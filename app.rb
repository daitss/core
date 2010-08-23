require 'bundler'
Bundler.setup

require 'ruby-debug'

require 'data_mapper'
require 'haml'
require 'net/http'
require 'nokogiri'
require 'sass'
require 'semver'
require 'sinatra'

require 'daitss/archive'
require 'daitss/config'
require 'daitss/datetime'
require 'daitss/db/ops/aip'
require 'daitss/db/ops/operations_events'
require 'daitss/db/ops/sip'
require 'daitss/db/ops/stashbin'
require 'daitss/proc/sip_archive'
require 'daitss/proc/wip/from_sip'
require 'daitss/proc/wip/process'
require 'daitss/proc/wip/progress'
require 'daitss/proc/wip/state'
require 'daitss/proc/workspace'

APP_VERSION = SemVer.find(File.dirname(__FILE__)).format "v%M.%m.%p%s"

configure do
  Daitss::CONFIG.load_from_env
  DataMapper.setup :default, Daitss::CONFIG['database-url']
end

helpers do

  def authenticate
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    error 401 unless @auth.provided? && @auth.basic? && @auth.credentials
    login, passwd = @auth.credentials
    @user ||= User.first :identifier => login
    error 401 unless @user
    error 401 unless user.authentication_key.auth_key == Digest::SHA1.hexdigest(passwd)
  end

  def require_param name
    params[name.to_s] or error 400, "parameter #{name} required"
  end

  def partial template, options={}
    haml template, options.merge!(:layout => false)
  end

end

before do
  #authenticate
  @user = Program.system_agent # comment this out when the above us incommented

  @archive = Archive.new
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

get '/submit' do
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
  @query = params['search']

  @packages = if @query
                ids = @query.strip.split
                Sip.all(:name => ids) | Sip.all(:id => ids)
              else
                t0 = Date.today - 7
                oes = OperationsEvent.all :timestamp.gt => t0
                oes.map { |oe| oe.sip }.uniq
              end

  @packages.sort! do |a,b|
    t_a = a.operations_events.last.timestamp
    t_b = b.operations_events.last.timestamp
    t_b <=> t_a
  end

  haml :packages
end

get '/package/:id' do |id|
  @sip = Sip.first :id => id
  not_found unless @sip
  @events = @sip.operations_events
  @wip = @archive.workspace[id]
  @aip = Aip.first :id => id
  @bin = StashBin.all.find { |b| File.exist? File.join(b.path, id) }
  @stashed_wip = @bin.wips.find { |w| w.id == id } if @bin
  @bins = StashBin.all
  @requests = @sip.requests

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
  @bins = StashBin.all
  @wip = @archive.workspace[id] or not_found
  haml :wip
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
    sip = Sip.first :id => wip_id
    sip.abort @user

    # remove package
    FileUtils.rm_rf stashed_wip_path

    # go home
    redirect "/package/#{wip_id}"

  else
    error 400

  end

end

get '/admin' do
  @bins = StashBin.all
  @accounts = Account.all
  @users = User.all
  @projects = Project.all

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
    a.name = require_param 'name'
    a.code = require_param 'code'
    a.save or error "could not create new account\n\n#{e.message}\n#{e.backtrace}"
    @archive.log "new account: #{a.name}"

  when 'delete-account'
    id = require_param 'id'
    a = Account.get(id) or not_found
    error 400, "cannot delete a non-empty account" unless a.projects.empty?
    a.destroy or error "could not delete account"
    @archive.log "delete account: #{a.name}"

  when 'new-project'
    account_code = require_param 'account'
    a = Account.first :code => account_code
    error 400, "account #{account_code} does not exist" unless a

    code = require_param 'code'
    name = require_param 'name'
    p = Project.new :name => name, :code => code
    p.account = a
    @archive.log "new project: #{p.name}"

    p.save or error "could not save project bin\n\n#{e.message}\n#{e.backtrace}"

  when 'delete-project'
    id = require_param 'id'
    p = Project.get(id) or not_found "no project"
    error 400, "cannot delete a non-empty project" unless p.sips.empty?
    p.destroy or error "could not delete project"
    @archive.log "delete project: #{p.name}"

  when 'new-user'
    type = require_param 'type'

    u = if type == "operator"
          Operator.new :account => Account.system_account
        else
          a = Account.first(:code => params['account'])
          Contact.new(:account => a,
                      :permissions => [:disseminate, :withdraw, :peek, :submit])
        end

    u.identifier = require_param 'username'
    u.first_name = require_param 'first_name'
    u.last_name = require_param 'last_name'
    u.email = require_param 'email'
    u.phone = require_param 'phone'
    u.address = require_param 'address'
    u.description = ""
    u.active_start_date = DateTime.now
    u.active_end_date = DateTime.now + 365

    u.save or error "could not save user, errors: #{u.errors}"
    @archive.log "new user: #{u.identifier}"

  when 'delete-user'
    id = require_param 'id'
    u = User.get(id) or not_found
    error 400, "cannot delete a non-empty user" unless u.operations_events.empty?
    u.destroy or error "could not delete user"
    @archive.log "delete user: #{u.identifier}"


  else raise "unknown task: #{params['task']}"
  end

  redirect '/admin'
end
