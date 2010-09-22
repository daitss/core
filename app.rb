require 'rubygems'
require 'bundler/setup'

require 'data_mapper'
require 'haml'
require 'sass'
require 'semver'
require 'sinatra'

require 'daitss'
require 'daitss/archive'
require 'daitss/config'
require 'daitss/datetime'
require 'daitss/model'
require 'daitss/proc/sip_archive'
require 'daitss/proc/wip/from_sip'
require 'daitss/proc/wip/process'
require 'daitss/proc/wip/progress'
require 'daitss/proc/wip/state'
require 'daitss/proc/workspace'

configure do
  Daitss::CONFIG.load_from_env
  Archive.setup_db
end

helpers do

  def authenticate
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    error 401 unless @auth.provided? && @auth.basic? && @auth.credentials
    login, passwd = @auth.credentials
    @user ||= User.first :identifier => login
    error 401 unless @user
    error 401 unless user.auth_key == Digest::SHA1.hexdigest(passwd)
  end

  def require_param name
    params[name.to_s] or error 400, "parameter #{name} required"
  end

  def partial template, options={}
    haml template, options.merge!(:layout => false)
  end

  def navlink name, href='#'
    partial :navlink, :locals => { :name => name, :href => href }
  end

end

before do
  #authenticate
  @user = Operator.get('root') or raise "cannot get root op"
  @archive = Archive.new
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do
  @active_nav = 'dashboard'
  haml :index
end

get '/log' do
  @active_nav = 'log'
  @entries = Entry.all
  haml :log
end

post '/log' do
  m = require_param 'message'
  @archive.log m
  redirect '/log'
end

get '/submit' do
  @active_nav = 'submit'
  haml :submit
end

post '/packages?/?' do
  #error 401 unless @user.account == account and @user.permissions.include? :submit
  require_param 'sip'

  sip = begin
          filename = params['sip'][:filename]
          data = params['sip'][:tempfile].read

          dir = Dir.mktmpdir
          path = File.join dir, filename
          open(path, 'w') { |io| io.write data }

          a = Archive.new
          a.submit path, @user
        ensure
          FileUtils.rm_r dir
        end

  redirect "/package/#{sip.id}"
end

get '/request' do
  haml :request
end

get '/delete_request/:ieid/:type' do |ieid, type|
  delete_request ieid, type

  redirect "/package/#{ieid}"
end

post '/request' do
  submit_request params['ieid'], params['type']

  redirect "/package/#{params['ieid']}"
end

get '/packages?/?' do
  @active_nav = 'packages'
  @query = params['search']

  @packages = if @query
                ids = @query.strip.split
                Sip.all(:name => ids).packages | Package.all(:id => ids)
              else
                t0 = Date.today - 7
                es = Event.all :timestamp.gt => t0
                es.map { |e| e.package }.uniq
              end

  @packages.sort! do |a,b|
    t_a = a.events.last.timestamp
    t_b = b.events.last.timestamp
    t_b <=> t_a
  end

  haml :packages
end

get '/package/:id' do |id|
  @active_nav = 'packages'
  @package = Package.get(id) or not_found
  @sip = @package.sip
  @wip = @archive.workspace[id]
  @aip = @package
  @bin = StashBin.all.find { |b| File.exist? File.join(b.path, id) }
  @stashed_wip = @bin.wips.find { |w| w.id == id } if @bin
  @bins = StashBin.all
  @requests = @package.requests
  
  ingest_start_event = @package.events.first(:name => "ingest started")
  ingest_finished_event = @package.events.first(:name => "ingest finished")

  if ingest_start_event and ingest_finished_event
    t = Time.parse(ingest_finished_event.timestamp.to_s) - Time.parse(ingest_start_event.timestamp.to_s)
    @ingest_time = t.to_i.to_s + " sec"
  end

  haml :package
end

get '/package/:id/descriptor' do |id|
  @active_nav = 'packages'
  @aip = Aip.first :id => id
  not_found unless @aip
  content_type = 'application/xml'
  @aip.xml
end

get '/workspace' do
  @active_nav = 'workspace'
  @bins = StashBin.all
  @ws = @archive.workspace
  haml :workspace
end

# workspace & wips in the workspace

post '/workspace' do
  ws = @archive.workspace

  case params['task']
  when 'start'
    startable = ws.reject { |w| w.running? or w.snafu? }
    startable.each { |wip| wip.start }

  when 'stop'
    stoppable = ws.select { |w| w.running? }
    stoppable.each { |wip| wip.stop }

  when 'unsnafu'
    unsnafuable = ws.select { |w| w.snafu? }
    unsnafuable.each { |wip| wip.unsnafu! }

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    bin = StashBin.first :name => params['stash-bin']
    stashable = ws.reject { |w| w.running? }
    stashable.each { |w| ws.stash w.id, bin }

  when nil, '' then error 400, "parameter task is required"
  else error 400, "unknown command: #{params['task']}"
  end

  redirect '/workspace'
end

get '/workspace/:id' do |id|
  @active_nav = 'workspace'
  @bins = StashBin.all
  @wip = @archive.workspace[id]

  if @wip
    haml :wip
  elsif Package.get(id)
    redirect "/package/#{id}"
  else
    not_found
  end

end

get '/workspace/:id/snafu' do |id|
  @active_nav = 'workspace'
  wip = @archive.workspace[id] or not_found
  not_found unless wip.snafu?
  content_type = 'text/plain'
  wip.snafu
end

post '/workspace/:id' do |id|
  ws = @archive.workspace
  wip = ws[id] or not_found

  case params['task']
  when 'start'
    error 400, 'cannot start a running wip' if wip.running?
    error 400, 'cannot start a snafu wip' if wip.snafu?
    wip.start

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
  @active_nav = 'stashspace'
  @bins = StashBin.all
  haml :stashspace
end

post '/stashspace' do
  name = require_param 'name'
  bin = StashBin.new :name => name
  bin.save or error "could not save bin\n\n#{e.message}\n#{e.backtrace}"
  @archive.log "new stash bin: #{name}"
  redirect "/stashspace/#{name}"
end

get '/stashspace/:bin' do |bin|
  @active_nav = 'stashspace'
  @bin = StashBin.first :name => bin
  haml :stash_bin
end

get '/stashspace/:bin/:wip' do |bin, wip|
  @active_nav = 'stashspace'
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
    p = Package.get wip_id
    p.abort @user

    # remove package
    FileUtils.rm_rf stashed_wip_path

    # go home
    redirect "/package/#{wip_id}"

  else
    error 400

  end

end

get '/admin' do
  @active_nav = 'admin'
  @bins = StashBin.all
  @accounts = Account.all :id.not => Archive::SYSTEM_ACCOUNT_ID
  @users = User.all
  @projects = Project.all :id.not => 'default'

  haml :admin
end

post '/admin' do

  case params['task']

  when 'new-stashbin'
    name = require_param 'name'
    bin = StashBin.new :name => name
    bin.save or error "could not save bin\n\n#{e.message}\n#{e.backtrace}"
    @archive.log "new stash bin: #{name}"

  when 'delete-stashbin'
    name = require_param 'name'
    bin = StashBin.first :name => name
    pattern = File.join bin.path, '*'
    error 400, "cannot delete a non-empty stash bin" unless Dir[pattern].empty?
    bin.destroy or raise "could not delete stash bin #{name}"
    FileUtils.rm_rf bin.path
    @archive.log "delete stash bin: #{name}"

  when 'new-account'
    a = Account.new
    a.id = require_param 'id'
    a.description = require_param 'description'
    p = Project.new :id => Archive::DEFAULT_PROJECT_ID, :description => 'default project'
    a.projects << p
    a.save or error "could not create new account"
    @archive.log "new account: #{a.id}"

  when 'delete-account'
    id = require_param 'id'
    a = Account.get(id) or not_found

    if a.projects == [a.default_project] and a.default_project.packages.empty?
      a.destroy or error "could not delete account"
    else
      error 400, "cannot delete a non-empty account"
    end

    @archive.log "delete account: #{a.id}"

  when 'new-project'
    account_id = require_param 'account_id'
    a = Account.get(account_id) or error 400, "account #{account_id} does not exist"
    id = require_param 'id'
    description = require_param 'description'
    p = Project.new :id => id, :description => description
    p.account = a
    @archive.log "new project: #{p.id}"
    p.save or error "could not save project bin\n\n#{e.message}\n#{e.backtrace}"

  when 'delete-project'
    id = require_param 'id'
    account_id = require_param 'account_id'
    p = Account.get(account_id).projects.first(:id => id) or not_found
    error 400, "cannot delete a non-empty project" unless p.packages.empty?
    p.destroy or error "could not delete project"
    @archive.log "delete project: #{p.id}"

  when 'new-user'
    type = require_param 'type'

    u = if type == "operator"
          Operator.new :account => Account.get("SYSTEM")
        else
          account_id = require_param 'account_id'
          a = Account.get account_id
          Contact.new :account => a, :permissions => [:disseminate, :withdraw, :peek, :submit]
        end

    u.id = require_param 'id'
    u.first_name = require_param 'first_name'
    u.last_name = require_param 'last_name'
    u.email = require_param 'email'
    u.phone = require_param 'phone'
    u.address = require_param 'address'
    u.description = ""
    u.save or error "could not save user, errors: #{u.errors}"
    @archive.log "new user: #{u.id}"

  when 'delete-user'
    id = require_param 'id'
    u = User.get(id) or not_found
    error 400, "cannot delete a non-empty user" unless u.events.empty?
    u.destroy or error "could not delete user"
    @archive.log "delete user: #{u.id}"

  else raise "unknown task: #{params['task']}"
  end

  redirect '/admin'
end
