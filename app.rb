require 'rubygems'
require 'bundler/setup'

require 'haml'
require 'sass'
require 'sinatra'
require 'daitss'

require 'daitss/archive/report'

include Daitss

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

configure do
  enable :method_override

  Daitss.archive
end

before do
  #authenticate
  @user = Operator.get('root') or raise "cannot get root op"
  @archive = Daitss.archive

  @active_nav = case ENV['PATH_INFO']
                when '/' then 'dashboard'
                when %r{^/log} then 'log'
                when %r{^/package} then 'packages'
                when %r{^/workspace} then 'workspace'
                when %r{^/stashspace} then 'stashspace'
                when %r{^/admin} then 'admin'
                else
                end

end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do
  haml :index
end

get '/log' do
  @entries = Entry.all
  haml :log
end

post '/log' do
  m = require_param 'message'
  @archive.log m
  redirect '/log'
end

post '/packages?/?' do
  require_param 'sip'

  sip = begin
          filename = params['sip'][:filename]
          data = params['sip'][:tempfile].read

          dir = Dir.mktmpdir
          path = File.join dir, filename
          open(path, 'w') { |io| io.write data }

          @archive.submit path, @user
        ensure
          FileUtils.rm_r dir
        end

  redirect "/package/#{sip.id}"
end

get '/packages?/?' do
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
  @package = Package.get(id) or not_found
  @bins = @archive.stashspace
  @bin = @archive.stashspace.find { |b| File.exist? File.join(b.path, id) }

  if @package.status == 'archived'
    @ingest_time = @package.elapsed_time.to_s + " sec"
  end

  haml :package
end

get '/package/:id/descriptor' do |id|
  @aip = Aip.first :id => id
  not_found unless @aip
  content_type = 'application/xml'
  @aip.xml
end

get '/package/:id/ingest_report' do |id|
  halt 404 unless Package.get(id).status == "archived"
  Archive.instance.ingest_report id
end

# enqueue a new request
post '/package/:id/request' do |id|
  @package = Package.get(id) or not_found
  type = require_param 'type'
  note = require_param 'note'
  r = Request.new

  r.type = type
  r.note = note

  @user.requests << r
  r.agent = @user
  @package.requests << r
  r.package = @package

  r.save or error "cannot save request: #{r.errors.inspect}"
  redirect "/package/#{id}"
end

# modify a request
post '/package/:pid/request/:rid' do |pid, rid|
  @package = Package.get(pid) or not_found
  @request = @package.requests.first(:id => rid) or not_found

  task = require_param 'task'
  error "unknown task: #{task}" unless task == 'delete'

  @request.destroy or error "cannot delete request: #{@request.errors.inspect}"
  redirect "/package/#{pid}"
end

get '/workspace' do
  @bins = @archive.stashspace
  @ws = @archive.workspace
  haml :workspace
end

# workspace & wips in the workspace

# TODO deprecate the multiple interface with js hitting each one
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
    bin = @archive.stashspace.find { |b| b.name == params['stash-bin'] }
    error 400, "bin #{bin} does not exist" unless bin
    stashable = ws.reject { |w| w.running? }
    stashable.each { |w| ws.stash w.id, bin }

  when nil, '' then error 400, "parameter task is required"
  else error 400, "unknown command: #{params['task']}"
  end

  redirect '/workspace'
end

get '/workspace/:id' do |id|
  @bins = @archive.stashspace
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
    bin = @archive.stashspace.find { |b| b.name == params['stash-bin'] }
    error 400, "bin #{bin} does not exist" unless bin
    ws.stash wip.id, bin
    redirect "/stashspace/#{bin.id}/#{wip.id}"

  when nil, '' then raise 400, 'parameter task is required'
  else error 400, "unknown command: #{params['task']}"
  end

  redirect "/workspace/#{wip.id}"
end

# stash bins & stashed wips

get '/stashspace' do
  @bins = @archive.stashspace
  haml :stashspace
end

post '/stashspace' do
  name = require_param 'name'
  bin = StashBin.make! name
  @archive.log "new stash bin: #{bin}"
  redirect "/stashspace"
end

get '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  @bin = @archive.stashspace.find { |b| b.id == id }
  not_found unless @bin
  haml :stash_bin
end

delete '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  bin = @archive.stashspace.find { |b| b.id == id }
  error 400, "cannot delete a non-empty stash bin" unless bin.empty?
  bin.delete or error "cannot not delete stash bin"
  @archive.log "delete stash bin: #{bin}"
  redirect "/stashspace"
end

get '/stashspace/:bin/:wip' do |b_id, w_id|
  b_id = URI.encode b_id # SMELL sinatra is decoding this

  @bin = @archive.stashspace.find { |b| b.id == b_id }
  not_found unless @bin

  @wip = @bin.find { |w| w.id == w_id }
  not_found unless @wip

  haml :stashed_wip
end

delete '/stashspace/:bin/:wip' do |b_id, w_id|
  b_id = URI.encode b_id # SMELL sinatra is decoding this

  @bin = @archive.stashspace.find { |b| b.id == b_id }
  not_found unless @bin

  @wip = @bin.find { |w| w.id == w_id }
  not_found unless @wip

  task = require_param 'task'

  case task
  when 'unstash'
    @bin.unstash w_id
    redirect "/workspace/#{w_id}"

  when 'abort'

    # write ops event for abort
    p = Package.get w_id
    p.abort @user

    # remove package
    FileUtils.rm_rf @wip.path

    # go home
    redirect "/package/#{w_id}"

  else
    error 400

  end

end

get '/admin' do
  @accounts = Account.all :id.not => Daitss::Archive::SYSTEM_ACCOUNT_ID
  @users = User.all
  @projects = Project.all :id.not => 'default'

  haml :admin
end

post '/admin' do

  case params['task']

  when 'new-account'
    a = Account.new
    a.id = require_param 'id'
    a.description = require_param 'description'
    a.report_email = require_param 'report-email'
    p = Project.new :id => Daitss::Archive::DEFAULT_PROJECT_ID, :description => 'default project'
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
