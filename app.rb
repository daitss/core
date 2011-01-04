require 'rubygems'
require 'bundler/setup'

require 'haml'
require 'sass'
require 'sinatra'
require 'rack/ssl-enforcer'
require 'daitss'
require 'ruby-debug'

require 'daitss/archive/report'

include Daitss
load_archive

# if there is an ssl server running uncomment this
# use Rack::SslEnforcer, :only => "/login"

class Login < Sinatra::Base
  enable :sessions

  get('/login') do
    haml :login
  end

  post('/login') do

    name = params[:name]
    password = params[:password]
    user = User.get name
    error 403 unless user

    if user.authenticate password
      session['user_name'] = user.id
      redirect '/'
    else
      session['user_name'] = nil
      error 403
    end


  end

  post('/logout') do

    if session['user_name']
      session.clear
      redirect '/login'
    else
      error 403
    end

  end

end

use Login

helpers do

  def require_param name
    params[name.to_s] or error 400, "parameter #{name} required"
  end

  def partial template, options={}
    haml template, options.merge!(:layout => false)
  end

end

configure do
  enable :method_override
  enable :sessions
end

before do

  unless %w(/stylesheet.css /favicon.ico).include? request.path
    @user = User.get session['user_name']
    redirect '/login' unless @user
  end

end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do
  haml :index
end

# log
before '/log' do
  error 403 unless @user.kind_of? Operator
end

get '/log' do
  @entries = Entry.all
  haml :log
end

post '/log' do
  m = require_param 'message'
  archive.log m
  redirect '/log'
end

post '/packages?/?' do
  require_param 'sip'

  p = begin
          filename = params['sip'][:filename]
          data = params['sip'][:tempfile].read
          batch_id = params["batch_id"].strip == "batch name" ? nil : params["batch_id"].strip
          note = params["note"] == "note" ? nil : params["note"].strip

          dir = Dir.mktmpdir
          path = File.join dir, filename
          open(path, 'w') { |io| io.write data }

          p = archive.submit path, @user, note

          if batch_id
            b = Batch.first_or_create(:id => batch_id)
            b.packages << p
            b.save
          end

          p
        ensure
          FileUtils.rm_r dir
        end

  redirect "/package/#{p.id}"
end

get '/packages?/?' do
  @query = params['search']
  @batches = Batch.all

  @packages = if @query
                ids = @query.strip.split
                @user.packages.sips.all(:name => ids).packages | @user.packages.all(:id => ids)
              else
                t0 = Date.today - 7
                es = @user.packages.events.all(:timestamp.gt => t0, :limit => 50, :order => [ :timestamp.desc ])
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
  @package = @user.packages.get(id) or not_found
  @bins = archive.stashspace
  @bin = archive.stashspace.find { |b| File.exist? File.join(b.path, id) }

  if @package.status == 'archived'
    @ingest_time = @package.elapsed_time.to_s + " sec"
  end

  haml :package
end

get '/package/:id/descriptor' do |id|
  @package = @user.packages.get(id) or not_found
  @aip = @package.aip or not_found
  not_found unless @aip
  content_type = 'application/xml'
  @aip.xml
end

get '/package/:id/ingest_report' do |id|
  @package = @user.packages.get(id) or not_found
  not_found unless @package.status == "archived"
  archive.ingest_report id
end

# enqueue a new request
post '/package/:id/request' do |id|
  @package = @user.packages.get(id) or not_found
  type = require_param 'type'
  note = require_param 'note'

  error 400, "#{type} request already enqueued" if @package.requests.first(:type => type, :status => :enqueued)

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
  @package = @user.packages.get(pid) or not_found
  req = @package.requests.first(:id => rid) or not_found

  task = require_param 'task'
  error "unknown task: #{task}" unless task == 'delete'

  req.cancel or error "cannot cancel request: #{req.errors.inspect}"
  @package.log "#{req.type} request cancelled", :notes => "cancelled by: #{@user.id}"

  redirect "/package/#{pid}"
end

before '/workspace' do
  error 403 unless @user.kind_of? Operator
end

get '/workspace' do
  @bins = archive.stashspace
  @ws = archive.workspace
  haml :workspace
end

# workspace & wips in the workspace
post '/workspace' do
  ws = archive.workspace

  case params['task']
  when 'start'
    startable = ws.reject { |w| w.running? or w.snafu? }
    startable.each do |w|
      w.unstop if w.stopped?
      w.reset_process if w.dead?
      w.spawn
    end

  when 'stop'
    ws.select(&:running?).each(&:stop)

  when 'unsnafu'
    ws.select(&:snafu?).each(&:unsnafu)

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    bin = archive.stashspace.find { |b| b.name == params['stash-bin'] }
    error 400, "bin #{bin} does not exist" unless bin
    stashable = ws.reject { |w| w.running? }
    stashable.each { |w| ws.stash w.id, bin }

  when nil, '' then error 400, "parameter task is required"
  else error 400, "unknown command: #{params['task']}"
  end

  redirect '/workspace'
end

get '/workspace/:id' do |id|
  @bins = archive.stashspace
  @wip = archive.workspace[id]

  if @wip
    haml :wip
  elsif Package.get(id)
    redirect "/package/#{id}"
  else
    not_found
  end

end

get '/workspace/:id/snafu' do |id|
  wip = archive.workspace[id] or not_found
  not_found unless wip.snafu?
  content_type = 'text/plain'
  wip.snafu
end

post '/workspace/:id' do |id|
  ws = archive.workspace
  wip = ws[id] or not_found

  case params['task']
  when 'start'
    wip.unstop if wip.stopped?
    wip.reset_process if wip.dead?
    error 400, 'cannot start a running wip' if wip.running?
    error 400, 'cannot start a snafu wip' if wip.snafu?
    wip.spawn

  when 'stop'
    error 400, 'cannot stop an idle wip' unless wip.running?
    wip.stop

  when 'unsnafu'
    error 400, 'can only unsnafu a snafu wip' unless wip.snafu?
    wip.unsnafu

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    error 400, 'can only stash a non-running wip' if wip.running?
    bin = archive.stashspace.find { |b| b.name == params['stash-bin'] }
    error 400, "bin #{bin} does not exist" unless bin
    ws.stash wip.id, bin
    redirect "/stashspace/#{bin.id}/#{wip.id}"

  when nil, '' then raise 400, 'parameter task is required'
  else error 400, "unknown command: #{params['task']}"
  end

  redirect "/workspace/#{wip.id}"
end

# stash bins & stashed wips
before '/stashspace' do
  error 403 unless @user.kind_of? Operator
end

get '/stashspace' do
  @bins = archive.stashspace
  haml :stashspace
end

post '/stashspace' do
  name = require_param 'name'
  bin = StashBin.make! name
  archive.log "new stash bin: #{bin}"
  redirect "/stashspace"
end

get '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  @bin = archive.stashspace.find { |b| b.id == id }
  not_found unless @bin
  haml :stash_bin
end

delete '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  bin = archive.stashspace.find { |b| b.id == id }
  error 400, "cannot delete a non-empty stash bin" unless bin.empty?
  bin.delete or error "cannot not delete stash bin"
  archive.log "delete stash bin: #{bin}"
  redirect "/stashspace"
end

get '/stashspace/:bin/:wip' do |b_id, w_id|
  b_id = URI.encode b_id # SMELL sinatra is decoding this

  @bin = archive.stashspace.find { |b| b.id == b_id }
  not_found unless @bin

  @wip = @bin.find { |w| w.id == w_id }
  not_found unless @wip

  haml :stashed_wip
end

delete '/stashspace/:bin/:wip' do |b_id, w_id|
  b_id = URI.encode b_id # SMELL sinatra is decoding this

  @bin = archive.stashspace.find { |b| b.id == b_id }
  not_found unless @bin

  @wip = @bin.find { |w| w.id == w_id }
  not_found unless @wip

  task = require_param 'task'

  case task
  when 'unstash'
    @bin.unstash w_id
    redirect "/workspace/#{w_id}"

  when 'abort'
    Package.get(w_id).abort @user
    @wip.retire
    redirect "/package/#{w_id}"

  else
    error 400

  end

end

before '/admin' do
  error 403 unless @user.kind_of? Operator
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
    archive.log "new account: #{a.id}"

  when 'delete-account'
    id = require_param 'id'
    a = Account.get(id) or not_found

    if a.projects == [a.default_project] and a.default_project.packages.empty?
      a.destroy or error "could not delete account"
    else
      error 400, "cannot delete a non-empty account"
    end

    archive.log "delete account: #{a.id}"

  when 'new-project'
    account_id = require_param 'account_id'
    a = Account.get(account_id) or error 400, "account #{account_id} does not exist"
    id = require_param 'id'
    description = require_param 'description'
    p = Project.new :id => id, :description => description
    p.account = a
    archive.log "new project: #{p.id}"
    p.save or error "could not save project bin\n\n#{e.message}\n#{e.backtrace}"

  when 'delete-project'
    id = require_param 'id'
    account_id = require_param 'account_id'
    p = Account.get(account_id).projects.first(:id => id) or not_found
    error 400, "cannot delete a non-empty project" unless p.packages.empty?
    p.destroy or error "could not delete project"
    archive.log "delete project: #{p.id}"

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
    u.encrypt_auth require_param('password')
    u.first_name = require_param 'first_name'
    u.last_name = require_param 'last_name'
    u.email = require_param 'email'
    u.phone = require_param 'phone'
    u.address = require_param 'address'
    u.description = ""
    u.save or error "could not save user, errors: #{u.errors}"
    archive.log "new user: #{u.id}"

  when 'delete-user'
    id = require_param 'id'
    u = User.get(id) or not_found
    error 400, "cannot delete a non-empty user" unless u.events.empty?
    u.destroy or error "could not delete user"
    archive.log "delete user: #{u.id}"

  when 'make-admin-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_admin_contact = true
    u.save or error "could not save user, errors: #{u.errors}"
    archive.log "made admin contact: #{u.id}"

  when 'make-tech-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_tech_contact = true
    u.save or error "could not save user, errors: #{u.errors}"
    archive.log "made tech contact: #{u.id}"

  when 'unmake-admin-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_admin_contact = false
    u.save or error "could not save user, errors: #{u.errors}"
    archive.log "unmade admin contact: #{u.id}"

  when 'unmake-tech-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_tech_contact = false
    u.save or error "could not save user, errors: #{u.errors}"
    archive.log "unmade tech contact: #{u.id}"



  else raise "unknown task: #{params['task']}"
  end

  redirect '/admin'
end

get "/batches" do
  @batches = Batch.all
  haml :batches
end

post "/batches" do
  name = require_param 'name'
  raw = require_param('packages').strip
  ps = raw.split %r{\s+}
  ps.map! { |id| Package.get id or raise "#{id} not found" }
  Batch.create :id => name, :packages => ps
  redirect "/batches"
end

get "/batches/:batch_id" do |batch_id|
  @batch = Batch.get(batch_id)

  halt 404 unless @batch
  haml :batch
end

post "/batches/:batch_id" do |batch_id|
  task = require_param 'task'

  @batch = Batch.get(batch_id)
  halt 404 unless @batch

  case task
  when "delete-batch"
    @batch.packages = []
    @batch.save
    @batch.destroy
    redirect "/batches"

  when "modify-batch"
    raw = require_param('packages').strip
    ps = raw.split %r{\s+}
    ps.map! { |id| Package.get id or raise "#{id} not found" }

    @batch.packages = ps
    @batch.save

    redirect "/batches/#{batch_id}"

  when 'request-batch'
    @batch.packages.each do |package|
      type = require_param 'type'

      r = Request.new

      r.type = type
      r.note = note if params['note']

      @user.requests << r
      r.agent = @user
      package.requests << r
      r.package = package

      r.save or error "cannot save request: #{r.errors.inspect}"
    end

    redirect "/batches"
  end
end

get '/requests' do
  @requests = Request.all

  # filter based on parameters passed in

  if params['batch-scope'] and params['batch-scope'] != 'all'
    b = Batch.get(params['batch-scope'])
    @requests = @requests.find_all {|r| b.packages.include? r.package }
  end

  if params['account-scope'] and params['account-scope'] != 'all'
    a = Account.get(params['account-scope'])

    @requests = @requests.find_all do |r|
      in_project = a.projects.map do |p|
        p.packages.include?(r.package) ? true : false
      end

      in_project.include? true
    end
  end

  if params['project-scope'] and params['project-scope'] != 'all'
    p = Project.first(:id => params['project-scope'].split("-")[0], :account_id => params['project-scope'].split("-")[1])
    @requests = @requests.find_all {|r| p.packages.include? r.package }
  end

  if params['user-scope'] and params['user-scope'] != 'all'
    u = User.get(params['user-scope'])
    @requests = @requests.find_all {|r| r.agent == u }
  end

  if params['type-scope'] and params['type-scope'] != 'all'
    case params['type-scope']
    when 'disseminate'
      scope = :disseminate
    when 'withdraw'
      scope = :withdraw
    when 'peek'
      scope = :peek
    end

    @requests = @requests.find_all {|r| r.type == scope }
  end

  if params['status-scope'] and params['status-scope'] != 'all'
    case params['status-scope']
    when 'enqueued'
      status = :enqueued
    when 'released'
      status = :released_to_workspace
    when 'cancelled'
      status = :cancelled
    end

    @requests = @requests.find_all {|r| r.status == status }
  end

  @params = params

  haml :requests
end
