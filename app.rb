require 'sinatra'
require 'haml'
require 'sass'
require 'net/http'
require 'nokogiri'

require 'workspace'
require 'wip/process'
require 'wip/state'
require 'wip/json'
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
  @events = OperationsEvent.all :ieid => id, :order => [:timestamp.asc]
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

  if request.accept.include? 'application/json'
    settings.workspace.to_json
  else
    haml :workspace
  end

end

post '/workspace' do
  ws = settings.workspace

  case params['task']
  when 'start'
    startable = ws.reject { |w| w.running? || w.done? }
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
  @wip = settings.workspace[id] or not_found

  if request.accept.include? 'application/json'
    @wip.to_json
  else
    haml :wip
  end

end

get '/workspace/:id/snafu' do |id|
  wip = settings.workspace[id] or not_found
  not_found unless wip.snafu?
  content_type = 'text/plain'
  wip.snafu
end

post '/workspace/:id' do |id|
  wip = settings.workspace[id] or not_found

  case params['task']
  when 'start'
    error 400, 'cannot start a running wip' if wip.running?
    wip.start_task

  when 'stop'
    error 400, 'cannot stop an idle wip' unless wip.running?
    wip.stop

  when 'unsnafu'
    error 400, 'can only unsnafu a snafu wip' unless wip.snafu?
    wip.unsnafu!

  when 'stash'
    error 400, 'parameter path is required' unless params['path']
    error 400, "#{params['path']} is not a directory" unless File.directory? params['path']
    FileUtils.mv wip.path, params['path']
    redirect '/'

  when nil, '' then raise 400, 'parameter task is required'
  else error 400, "unknown command: #{params['task']}"
  end

  redirect wip.id
end

get '/stash' do
  @bins = StashBin.all
  haml :stashbins
end

get '/stash/:bin' do |bin|
  @bin = StashBin.first :name => bin
  haml :stashbin
end

get '/stash/:bin/:wip' do |bin, wip|
  @bin = StashBin.first :bin => bin
  haml :stashbin
end
