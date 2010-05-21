require 'sinatra'
require 'haml'
require 'sass'
require 'net/http'
require 'nokogiri'

require 'workspace'
require 'wip/process'
require 'wip/state'
require 'wip/progress'
require 'daitss/config'

require 'datamapper'
require 'dm-aggregates'
require 'aip'
require 'stashbin'
require 'db/sip'
require 'db/operations_events'

configure do
  Daitss::CONFIG.load_from_env
  ws = Workspace.new(Daitss::CONFIG['workspace'])
  set :workspace, ws
  DataMapper.setup :default, Daitss::CONFIG['database-url']

  #Thread.new do

    #loop do
      #startable = ws.select { |w| w.state == 'idle' }

      #startable.each do |wip|
        #puts "starting #{wip.id}"
        #wip.start_task
      #end

      #sleep 1
    #end

  #end

end

helpers do

  def submit data, sip, ext
    url = Daitss::CONFIG['submission-url']

    url = URI.parse url
    req = Net::HTTP::Post.new url.path
    req.body = data
    req.content_type = 'application/tar'
    req.basic_auth 'operator', 'operator'
    req['X-Package-Name'] = sip
    req['Content-MD5'] = Digest::MD5.hexdigest data
    req['X-Archive-Type'] = ext

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

    res.error! unless Net::HTTPSuccess === res

    doc = Nokogiri::XML res.body
    (doc % 'IEID').content
  end

  def search query
    ids = query.strip.split
    SubmittedSip.all(:package_name => ids) | SubmittedSip.all(:ieid => ids)
  end

end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do
  haml :index
end

get '/submit' do
  haml :submit
end

post '/submit' do

  data, sip, ext = begin
                     filename = params['sip'][:filename]
                     sip = filename[ %r{^(.+)\.\w+$}, 1]
                     ext = filename[ %r{^.+\.(\w+)$}, 1]
                     data = params['sip'][:tempfile].read
                     [data, sip, ext]
                   rescue
                     error 400, 'file upload parameter "sip" required'
                   end

  id = submit data, sip, ext
  redirect "/package/#{id}"
end

get '/packages?' do

  if params['search']
    @query = params['search']
    @results = search @query
  end

  haml :packages
end

get '/package/:id' do |id|
  @sip = SubmittedSip.first :ieid => id
  not_found unless @sip
  @events = @sip.operations_events
  @wip = settings.workspace[id]
  @aip = Aip.first :id => id
  haml :package
end

get '/package/:id/descriptor' do |id|
  @aip = Aip.first :id => id
  not_found unless @aip
  content_type = 'application/xml'
  @aip.xml
end

get '/workspace' do
  @bins = StashBin.all
  @ws = settings.workspace
  haml :workspace
end

# workspace & wips in the workspace

post '/workspace' do
  ws = settings.workspace

  case params['task']
  when 'start'
    startable = ws.reject { |w| w.running? or w.done? or w.snafu? }
    startable.each { |wip| wip.start_task }

  when 'stop'
    stoppable = ws.select { |w| w.running? }
    stoppable.each { |wip| wip.stop }

  when 'unsnafu'
    unsnafuable = ws.select { |w| w.snafu? }
    unsnafuable.each { |wip| wip.unsnafu! }

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    bin = StashBin.first :name => params['stash-bin']
    stashable = ws.reject { |w| w.running? || w.done? }
    stashable.each { |w| ws.stash w.id, bin }

  when nil, '' then error 400, "parameter task is required"
  else error 400, "unknown command: #{params['task']}"
  end

  redirect '/workspace'
end

get '/workspace/:id' do |id|
  @bins = StashBin.all
  @wip = settings.workspace[id] or not_found
  haml :wip
end

get '/workspace/:id/snafu' do |id|
  wip = settings.workspace[id] or not_found
  not_found unless wip.snafu?
  content_type = 'text/plain'
  wip.snafu
end

post '/workspace/:id' do |id|
  ws = settings.workspace
  wip = ws[id] or not_found

  case params['task']
  when 'start'
    error 400, 'cannot start a running wip' if wip.running?
    error 400, 'cannot start a snafu wip' if wip.snafu?
    wip.start_task

  when 'stop'
    error 400, 'cannot stop an idle wip' unless wip.running?
    wip.stop

  when 'unsnafu'
    error 400, 'can only unsnafu a snafu wip' unless wip.snafu?
    wip.unsnafu!

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    error 400, 'can only stash a non-running wip' if wip.running?
    bin = StashBin.first :name => params['stash-bin']
    ws.stash wip.id, bin
    redirect "/stashspace/#{bin.url_name}/#{wip.id}"

  when nil, '' then raise 400, 'parameter task is required'
  else error 400, "unknown command: #{params['task']}"
  end

  redirect "/workspace/#{wip.id}"
end

# stash bins & stashed wips

get '/stashspace' do
  @bins = StashBin.all
  haml :stashspace
end

get '/stashspace/:bin' do |bin|
  @bin = StashBin.first :name => bin
  haml :stash_bin
end

get '/stashspace/:bin/:wip' do |bin, wip|
  @bin = StashBin.first :name => bin
  @wip = Wip.new File.join(@bin.path, wip)
  haml :stashed_wip
end

post '/stashspace/:bin/:wip' do |bin_name, wip_id|

  # the bin
  bin = StashBin.first :name => bin_name
  not_found "#{bin.name}" unless bin

  # the win in the bin
  stashed_wip_path = File.join(bin.path, wip_id)
  not_found "#{bin.name}" unless File.exist? stashed_wip_path

  case params['task']
  when 'unstash'
    bin.unstash wip_id
    redirect "/workspace/#{wip_id}"

  when 'abort'
    # write ops event for abort
    sip = SubmittedSip.first :ieid => wip_id
    event = OperationsEvent.new :event_name => 'Abort'
    event.operations_agent = Program.system_agent
    event.submitted_sip = sip
    event.save or raise "cannot save op event"

    # remove package
    FileUtils.rm_rf stashed_wip_path

    # go home
    redirect "/package/#{wip_id}"

  else
    error 400

  end

end

# admin console

get '/admin' do
  @bins = StashBin.all
  haml :admin
end

post '/admin' do

  if params['new-stash-bin']
    bin = StashBin.new :name => params['new-stash-bin']
    bin.save or error "could not save create bin\n\n#{e.message}\n#{e.backtrace}"
  end

  if params['delete-stash-bin']

    params['delete-stash-bin'].each do |name|
      bin = StashBin.first :name => name
      pattern = File.join bin.path, '*'
      error 400, "cannot delete a non-empty stash bin" unless Dir[pattern].empty?
      bin.destroy or raise "could not delete stash bin #{name}"
      FileUtils.rm_rf bin.path
    end

  end

  redirect '/admin'
end
