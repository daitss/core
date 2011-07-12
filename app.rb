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

set :session_secret, Digest::SHA1.file(ENV['CONFIG']).hexdigest
enable :sessions

# if there is an ssl server running uncomment this
# use Rack::SslEnforcer, :only => "/login"
class Login < Sinatra::Base

  get('/login') do
    haml :login
  end

  post('/login') do
    name = params[:name]
    password = params[:password]
    user = User.get name
    error 403, "Failed login: please check your username and password and try again." unless user

    if user.authenticate password
      session['user_name'] = user.id
      redirect '/'
    else
      session['user_name'] = nil
      error 403, "Failed login: please check your username and password and try again."
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

  def require_ops
    error 403 unless @user.kind_of? Operator
  end

  def require_account act_id
    error 403 unless @user.account.id == act_id
  end

  def partial template, options={}
    haml template, options.merge!(:layout => false)
  end

  def is_op
    @user.kind_of? Operator
  end

  def is_affiliate
    @user.kind_of? Contact
  end

  def wip_sort_order w
    if w.running? then 3
    elsif w.state == :idle then 5
    elsif w.snafu? then 1
    elsif w.stopped? then 2
    elsif w.dead? then 4
    else 0
    end
  end

  def throttles type
    case type
    when :ingest;           archive.ingest_throttle        != 1 ? "#{archive.ingest_throttle} ingests;"               : "1 ingest;"
    when :dissemination;    archive.dissemination_throttle != 1 ? "#{archive.dissemination_throttle} disseminations;" : "1 dissemination;"
    when :withdrawal;       archive.withdrawal_throttle    != 1 ? "#{archive.withdrawal_throttle} withdrawals;"       : "1 withdrawal;"
    when :d1refresh;        archive.d1refresh_throttle     != 1 ? "#{archive.d1refresh_throttle} d1 refreshes;"       : "1 d1 refresh;"
    else ; "huh?"
    end
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

# TODO

# ops perms
[ '/log*', '/profile*', '/errors*', '/workspace*', '/stashspace*', '/admin*', '/batches*', '/requests*' ].each do |path|
  before(path) { require_ops }
end

# TODO figure out perm semantics
#  limit to just account data, no wips, reqs, etc
#
#  get '/'
# post '/packages?/?'
#  get '/packages?/?'
#  get '/package/:id'
#  get '/package/:id/descriptor'
#  get '/package/:p_id/dip/:d_id'
#  get '/package/:id/ingest_report'
# post '/package/:id/request'
# post '/package/:pid/request/:rid'

get '/profile' do
  js = Dir.chdir(archive.profile_path) { Dir['*.journal'] }
  @profs = js.map { |f| f.split('.') + ['profile'] }
  haml :profile
end

get '/profile/:package/:task/:pid/journal' do |package, task, pid|
  f = File.join archive.profile_path, "#{package}.#{task}.#{pid}.journal"
  marsh = open(f) { |io| Marshal.load io }

  unless marsh.empty?
    @steps = marsh.sort { |a,b| a[1][:time] <=> b[1][:time] }
    @elapsed_time = @steps[-1][1][:time] - @steps[0][1][:time]
    @duration = marsh.inject(0) { |acc,(n,s)| acc += s[:duration] }
    @elapsed_time += @steps[-1][1][:duration]
    haml :prof_journal
  else
    'no journal data'
  end

end

get '/profile/:package/:task/:pid/profile' do |package, task, pid|
  f = File.join archive.profile_path, "#{package}.#{task}.#{pid}.prof.html"
  send_file f
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
  archive.log m, @user
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

get '/daitss_report_xhtml.xsl' do
  headers 'Content-Disposition' => 'attachment; filename=daitss_report_xhtml.xsl'
  File.read("public/daitss_report_xhtml.xsl")
end

get '/packages?/?' do
  @query = params['search']
  @batches = Batch.all
  @is_op = is_op

  @packages = if @query and @query.length > 0
                ids = @query.strip.split
                @user.packages.sips.all(:name => ids).packages | @user.packages.all(:id => ids)
              elsif params['filter'] == 'true'
                @filter = true


                # filter on status
                names = case params['activity-scope']
                        when 'submitted'
                          "submit"
                        when 'rejected'
                          "reject"
                        when 'archived'
                          "ingest finished"
                        when 'disseminated'
                          "disseminate finished"
                        when 'error'
                          ["ingest snafu", "disseminate snafu", "d1refresh snafu"]
                        when 'withdrawn'
                          "withdraw finished"
                        else
                          ['submit', "reject", "ingest finished", "disseminate finished", "ingest snafu", "disseminate snafu", "withdraw finished", "daitss v.1 provenance"]
                        end

                # filter on date range
                start_date = if params['start_date'] and !params['start_date'].strip.empty?
                               Time.parse params['start_date']
                             else
                               Time.at 0
                             end

                end_date = if params['end_date'] and !params['end_date'].strip.empty?
                             Time.parse params['end_date']
                           else
                             Time.now
                           end

                end_date += 1
                range = (start_date..end_date)

                # lookup account, project if passed in
                account = Account.get(params['account-scope'])

                project_id, account_id = params['project-scope'].split("-")
                act = Account.get(account_id)
                project = act.projects.first(:id => project_id) if act

                # conflicting search, return empty set
                if account and act and account.id != act.id
                  ps = Package.all(:limit => 0)

                # account but not project specified
                elsif account and !project
                  ps = account.projects.packages.events.all(:timestamp => range, :name => names, :order => [ :timestamp.desc ] ).packages if is_op
                  ps = account.projects.packages.events.all(:limit => 500, :timestamp => range, :name => names, :order => [ :timestamp.desc ] ).packages unless is_op

                # project specified
                elsif project
                  ps = project.packages.events.all(:timestamp => range, :name => names, :order => [ :timestamp.desc ]).packages if is_op
                  ps = project.packages.events.all(:limit => 500, :timestamp => range, :name => names, :order => [ :timestamp.desc ]).packages unless is_op

                # neither account nor project specified
                else
                  ps = Event.all(:timestamp => range, :name => names, :order => [ :timestamp.desc ]).packages if is_op
                  ps = Event.all(:limit => 500, :timestamp => range, :name => names, :order => [ :timestamp.desc ]).packages unless is_op
                end

                # filter on batches
                batch = Batch.get(params['batch-scope'])

                if batch
                  ps = ps.find_all { |p| p.batches.include? batch } 
                end

                ps
              else
                start_date = Time.now - (60 * 60 * 24 * 4)
                end_date = Time.now
                range = (start_date..end_date)
                names = ["submit", "reject", "ingest finished", "disseminate finished", "ingest snafu", "disseminate snafu", "withdraw", "abort"]

                if @is_op
                  ps = Event.all(:timestamp => range, :name => names, :limit => 150, :order => [ :timestamp.desc ]).packages
                else
                  ps = @user.account.projects.packages.events.all(:timestamp => range, :name => names, :limit => 150, :order => [ :timestamp.desc ]).packages
                end
              end

  @packages.sort! do |a,b|
    t_a = a.events.last.timestamp
    t_b = b.events.last.timestamp
    t_b <=> t_a
  end

  haml :packages
end

get '/errors' do

  if @params['filter'] == 'true'

    # filter on date range
    start_date = if params['start_date'] and !params['start_date'].strip.empty?
                   Time.parse params['start_date']
                 else
                   Time.at 0
                 end

    end_date = if params['end_date'] and !params['end_date'].strip.empty?
                 Time.parse params['end_date']
               else
                 Time.now
               end

    end_date += 1
    range = (start_date..end_date)

    #lookup account, project if passed in
    account = Account.get(params['account-scope'])

    project_id, account_id = params['project-scope'].split("-")
    act = Account.get(account_id)
    project = act.projects.first(:id => project_id) if act

    # conflicting search, return empty set
    if account and act and account.id != act.id
      es = Package.all(:limit => 0)

      # account but not project specified
    elsif account and !project
      es = account.projects.packages.events.all(:timestamp => range, :name.like => "% snafu", :order => [ :timestamp.desc ] ).packages

      # project specified
    elsif project
      es = project.packages.events.all(:timestamp => range, :name.like => "% snafu", :order => [ :timestamp.desc ]).packages

      # neither account nor project specified
    else
      es = Event.all(:timestamp => range, :name.like => "% snafu", :order => [ :timestamp.desc ]).packages
    end

    # filter on batches
    batch = Batch.get(params['batch-scope'])
    
    if batch
      es = es.find_all { |p| p.batches.include? batch } 
    end

    # filter on status
    case params['activity-scope']
    when "error"
      es = es.reject do |e|
        latest_snafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "% snafu")
        latest_unsnafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "%unsnafu") 
        latest_stash_event = e.events.first(:order => [ :timestamp.desc ], :name => "stash") 

        has_unsnafu = latest_unsnafu_event ? latest_snafu_event.timestamp <= latest_unsnafu_event.timestamp : false
        has_stash = latest_stash_event ? latest_snafu_event.timestamp <= latest_stash_event.timestamp : false

        has_unsnafu or has_stash
      end
    when "reset"
      es = es.find_all do |e|
        latest_snafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "% snafu")
        latest_unsnafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "%unsnafu") 

        latest_unsnafu_event ? latest_unsnafu_event.timestamp >= latest_snafu_event.timestamp : false
      end
    when "stashed"
      es = es.find_all do |e|
        latest_snafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "% snafu")
        latest_stash_event = e.events.first(:order => [ :timestamp.desc ], :name => "stash") 

        latest_stash_event ? latest_stash_event.timestamp >= latest_snafu_event.timestamp : false
      end
    end

    # filter on error message
    if params['error-message'] and !params['error-message'].strip.empty?
      es = es.find_all do |e|
        latest_snafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "% snafu")

        latest_snafu_event.notes == params['error-message']
      end
    end

  else
    es = Event.all(:order => [ :timestamp.desc ], :name.like => "% snafu")
    es = es.map { |e| e.package }.uniq
  end


  # packages that have a "finished" event after last snafu event should be discarded
  @packages = es.reject do |e|
    latest_snafu_event = e.events.first(:order => [ :timestamp.desc ], :name.like => "% snafu")

    if latest_snafu_event
      snafu_timestamp = Time.parse(latest_snafu_event.timestamp.to_s)
      e.events.first(:name.like => "%finished", :timestamp.gt => snafu_timestamp)
    end
  end

  haml :snafus
end

get '/package/:id' do |id|
  @package = @user.packages.get(id) or not_found
  @bins = archive.stashspace
  @bin = archive.stashspace.find { |b| File.exist? File.join(b.path, id) }
  @is_op = is_op

  @fixity_events = params["fixity_events"] == "true"

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

get '/package/:p_id/dip/:d_id' do |p_id, d_id|
  @package = @user.packages.get(p_id) or not_found
  dip_path = File.join archive.disseminate_path, d_id
  File.exist?(dip_path) or not_found
  send_file dip_path
end

get '/package/:id/ingest_report' do |id|
  @package = @user.packages.get(id) or not_found
  not_found unless @package.status == "archived"
  headers 'Content-Disposition' => "attachment; filename=#{id}.xml"
  archive.ingest_report id
end

# enqueue a new request
post '/package/:id/request' do |id|
  @package = @user.packages.get(id) or not_found
  type = require_param 'type'
  note = require_param 'note'

  error 400, "#{type} request already enqueued" if @package.requests.first(:type => type, :status => :enqueued)
  error 400, "request submissions must include a note" unless note and note != ""

  r = Request.new

  r.type = type
  r.note = note
  r.is_authorized = false if r.type == :withdraw

  @user.requests << r
  r.agent = @user
  @package.requests << r
  r.package = @package

  r.save or error "cannot save request: #{r.errors.inspect}"

  @package.log "#{r.type} request placed", :notes => "request id: #{r.id}", :agent => @user

  redirect "/package/#{id}"
end

# modify a request
post '/package/:pid/request/:rid' do |pid, rid|
  @package = @user.packages.get(pid) or not_found
  req = @package.requests.first(:id => rid) or not_found

  task = require_param 'task'
  error "unknown task: #{task}" unless task == 'delete' or task == 'authorize'

  case task
  when 'delete'
    cancel_note = require_param 'cancel_note'
    error 400, "request cancellations must include a note" unless cancel_note and cancel_note != ""

    req.cancel or error "cannot cancel request: #{req.errors.inspect}"
    @package.log "#{req.type} request cancelled", :notes => "request id: #{req.id}; cancelled by: #{@user.id}; #{cancel_note}", :agent => @user
  when 'authorize'
    error 403, "withdraw requests cannot be authorized by the user that requested the withdrawal" unless @user.id != req.agent.id
    req.is_authorized = true
    req.save
    @package.log "#{req.type} request authorized", :notes => "authorized by: #{@user.id}", :agent => @user
  end

  redirect "/package/#{pid}"
end

get '/workspace' do
  @wips = archive.workspace.to_a
  @bins = archive.stashspace

  if params['filter'] == 'true'

    # filter wips by date range
    start_date = if params['start_date'] and !params['start_date'].strip.empty?
                   Time.parse params['start_date']
                 else
                   Time.at 0
                 end

    end_date = if params['end_date'] and !params['end_date'].strip.empty?
                 Time.parse params['end_date']
               else
                 Time.now
               end

    end_date += 1
    @wips = @wips.select {|w| File.ctime(w.path) >= start_date and File.ctime(w.path) <= end_date }

    # filter wips by batch

    batch = Batch.get(params['batch-scope'])

    if batch
      package_ids = batch.packages.map(&:id).to_set
      @wips = @wips.select {|w| package_ids.include? w.id }
    end

    # filter wips by account
    account = Account.get(params['account-scope'])

    if account
      package_ids = account.projects.packages.all(:id => @wips.map(&:id)).map(&:id).to_set
      @wips = @wips.select {|w| package_ids.include? w.id }
    end

    # filter wips by project
    project_id, account_id = params['project-scope'].split("-")
    act = Account.get(account_id)
    project = act.projects.first(:id => project_id) if act

    if project
      package_ids = project.packages.all(:id => @wips.map(&:id)).map(&:id).to_set
      @wips = @wips.select {|w| package_ids.include? w.id }
    end

    # filter wips by status

    status = params["status-scope"]

    case status
    when "running"
      @wips = @wips.select {|w| w.running? == true }
    when "idle"
      @wips = @wips.select {|w| w.state == :idle }
    when "error"
      @wips = @wips.select {|w| w.snafu? == true }
    when "stopped"
      @wips = @wips.select {|w| w.stopped? == true }
    when "dead"
      @wips = @wips.select {|w| w.dead? == true }
    end
  end

  @wips.sort! do |a,b|
    wip_sort_order(a) <=> wip_sort_order(b)
  end

  haml :workspace
end

# workspace & wips in the workspace
post '/workspace' do
  ws = archive.workspace

  case params['task']
  when 'start'
    note = require_param 'note'

    if @params['filter'] == 'true'
      startable = @params['wips'].map {|w| Wip.new(File.join(ws.path, w))}
      startable = startable.reject { |w| w.running? or w.snafu? }
    else
      startable = ws.reject { |w| w.running? or w.snafu? }
    end

    startable.each do |w|
      w.unstop if w.stopped?
      w.reset_process if w.dead?
      w.spawn note, @user
    end

  when 'stop'
    note = require_param 'note'

    if @params['filter'] == 'true'
      wip_list = @params['wips'].map {|w| Wip.new(File.join(ws.path, w))}
      wip_list.select(&:running?).each { |w| w.stop note }
    else
      ws.select(&:running?).each { |w| w.stop note, @user }
    end

  when 'unsnafu'
    note = require_param 'note'

    if @params['filter'] == 'true'
      wip_list = @params['wips'].map {|w| Wip.new(File.join(ws.path, w))}
      wip_list.select(&:snafu?).each { |w| w.unsnafu note }
    else
      ws.select(&:snafu?).each { |w| w.unsnafu note, @user }
    end

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    note = require_param 'note'
    bin = archive.stashspace.find { |b| b.name == params['stash-bin'] }
    error 400, "bin #{bin} does not exist" unless bin

    if @params['filter'] == 'true'
      stashable = @params['wips'].map {|w| Wip.new(File.join(ws.path, w))}
      stashable = stashable.reject { |w| w.running? }
    else
      stashable = ws.reject { |w| w.running? }
    end

    stashable.each { |w| ws.stash w.id, bin, note, @user }

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

  note = require_param 'note'
  note = nil if note.empty?

  case params['task']
  when 'start'
    wip.unstop if wip.stopped?
    wip.reset_process if wip.dead?
    error 400, 'cannot start a running wip' if wip.running?
    error 400, 'cannot start a snafu wip' if wip.snafu?
    wip.spawn note, @user

  when 'stop'
    error 400, 'cannot stop an idle wip' unless wip.running?
    wip.stop note, @user

  when 'unsnafu'
    error 400, 'can only unsnafu a snafu wip' unless wip.snafu?
    wip.unsnafu note, @user

  when 'stash'
    error 400, 'parameter stash-bin is required' unless params['stash-bin']
    error 400, 'can only stash a non-running wip' if wip.running?
    bin = archive.stashspace.find { |b| b.name == params['stash-bin'] }
    error 400, "bin #{bin} does not exist" unless bin
    ws.stash wip.id, bin, note, @user
    redirect "/stashspace/#{bin.id}/#{wip.id}"

  when nil, '' then raise 400, 'parameter task is required'
  else error 400, "unknown command: #{params['task']}"
  end

  redirect "/workspace/#{wip.id}"
end

# stash bins & stashed wips
get '/stashspace' do
  @bins = archive.stashspace
  haml :stashspace
end

post '/stashspace' do
  name = require_param 'name'
  bin = StashBin.make! name
  archive.log "new stash bin: #{bin}", @user
  redirect "/stashspace"
end

get '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  @bin = archive.stashspace.find { |b| b.id == id }
  @wips = archive.stashspace.find { |b| b.id == id }
  not_found unless @wips

  if params['filter'] == 'true'
    # filter wips by date range
    start_date = if params['start_date'] and !params['start_date'].strip.empty?
                   Time.parse params['start_date']
                 else
                   Time.at 0
                 end

    end_date = if params['end_date'] and !params['end_date'].strip.empty?
                 Time.parse params['end_date']
               else
                 Time.now
               end

    end_date += 1
    @wips = @wips.select {|w| File.ctime(w.path) >= start_date and File.ctime(w.path) <= end_date }

    # filter wips by batch

    batch = Batch.get(params['batch-scope'])

    if batch
      package_ids = batch.packages.map(&:id).to_set
      @wips = @wips.select {|w| package_ids.include? w.id }
    end

    # filter wips by account
    account = Account.get(params['account-scope'])

    if account
      package_ids = account.projects.packages.all(:id => @wips.map(&:id)).map(&:id).to_set
      @wips = @wips.select {|w| package_ids.include? w.id }
    end

    # filter wips by project
    project_id, account_id = params['project-scope'].split("-")
    act = Account.get(account_id)
    project = act.projects.first(:id => project_id) if act

    if project
      package_ids = project.packages.all(:id => @wips.map(&:id)).map(&:id).to_set
      @wips = @wips.select {|w| package_ids.include? w.id }
    end

    # filter wips by status

    case params["status-scope"]
    when "running"
      @wips = @wips.select {|w| w.running? == true }
    when "idle"
      @wips = @wips.select {|w| w.state == :idle }
    when "error"
      @wips = @wips.select {|w| w.snafu? == true }
    when "stopped"
      @wips = @wips.select {|w| w.stopped? == true }
    when "dead"
      @wips = @wips.select {|w| w.dead? == true }
    end
  end

  haml :stash_bin
end

post '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  @bin = archive.stashspace.find { |b| b.id == id }
  not_found unless @bin
  @bin.each { |wip| @bin.unstash wip.id, @user, "" }
  redirect "/stashspace/#{@bin.id}"
end

delete '/stashspace/:id' do |id|
  id = URI.encode id # SMELL sinatra is decoding this
  bin = archive.stashspace.find { |b| b.id == id }
  error 400, "cannot delete a non-empty stash bin" unless bin.empty?
  bin.delete or error "cannot not delete stash bin"
  archive.log "delete stash bin: #{bin}", @user
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
    note = require_param 'note'
    @bin.unstash w_id, @user, note
    redirect "/workspace/#{w_id}"

  when 'abort'
    note = require_param 'note'
    error 400, 'note required for abort' if note.empty?
    Package.get(w_id).abort @user, note
    @wip.retire
    redirect "/package/#{w_id}"

  else
    error 400

  end

end

get '/admin' do
  redirect '/admin/accounts'
end

get '/admin/:sub' do |sub|
  @accounts = Account.all :id.not => Daitss::Archive::SYSTEM_ACCOUNT_ID
  @projects = Project.all :id.not => 'default'
  @sub = sub
  @users = []

  Operator.all.each {|o| @users.push o }
  Contact.all.each {|c| @users.push c }

  haml :admin
end

get '/admin/accounts/:aid' do |account_id|
  @account = Account.get(account_id)
  error 404 unless @account

  haml :admin_account
end

get '/admin/projects/:aid/:pid' do |account_id, project_id|
  @project = Project.get(project_id, account_id)
  error 404 unless @project

  haml :admin_project
end

get '/admin/users/:uid' do |user_id|
  @the_user = User.get(user_id)
  error 404 unless @the_user

  haml :admin_user
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

    if a.save
      archive.log "new account: #{a.id}", @user
    else
      error "could not create new account"
    end

    redirect '/admin/accounts'

  when 'delete-account'
    id = require_param 'id'
    a = Account.get(id) or not_found

    if a.projects == [a.default_project] and a.default_project.packages.empty?
      if a.destroy 
        archive.log "delete account: #{a.id}", @user
      else 
        error "could not delete account"
      end
    else
      error 400, "cannot delete a non-empty account"
    end

    redirect '/admin/accounts'

  when 'modify-account'
    id = require_param 'id'
    a = Account.get(id) or not_found

    a.description = require_param 'description'
    a.report_email = require_param 'report-email'

    if a.save 
      archive.log "updated account: #{a.id}", @user
    else
      error "could not update account"
    end 

    redirect '/admin/accounts'

  when 'new-project'
    begin
      account_id = require_param 'account_id'
      a = Account.get(account_id) or error 400, "account #{account_id} does not exist"
      id = require_param 'id'
      description = require_param 'description'
      p = Project.new :id => id, :description => description
      p.account = a

      if p.save 
        archive.log "new project: #{p.id}", @user
      else
        error "could not save project bin\n\n#{e.message}\n#{e.backtrace}"
      end

      redirect '/admin/projects'
    rescue DataObjects::IntegrityError
      error 400, "bad project id, #{p.id} already exists in account #{account_id}"
    end

  when 'modify-project'
    account_id = require_param 'account_id'
    id = require_param 'id'
    p = Project.get(id, account_id) or not_found
    p.description = require_param 'description'

    if p.save 
      archive.log "updated project: #{p.id} (#{p.account.id})", @user
    else
      error "could not update project"
    end

    redirect '/admin/projects'

  when 'delete-project'
    id = require_param 'id'
    account_id = require_param 'account_id'
    p = Account.get(account_id).projects.first(:id => id) or not_found
    error 400, "cannot delete a non-empty project" unless p.packages.empty?

    if p.destroy
      archive.log "delete project: #{p.id}", @user
    else
      error "could not delete project"
    end

    redirect '/admin/projects'

  when 'new-user'
    error 400 if User.get(require_param('id'))

    type = require_param 'type'

    u = if type == "operator"
          Operator.new :account => Account.get("SYSTEM")
        else
          account_id = require_param 'account_id'
          a = Account.get account_id

          perms = []
          perms.push :disseminate if params['disseminate_perm'] == "on"
          perms.push :withdraw if params['withdraw_perm'] == "on"
          perms.push :peek if params['peek_perm'] == "on"
          perms.push :submit if params['submit_perm'] == "on"
          perms.push :report if params['report_perm'] == "on"

          Contact.new :account => a, :permissions => perms
        end

    u.id = require_param 'id'
    u.encrypt_auth require_param('password')
    u.first_name = require_param 'first_name'
    u.last_name = require_param 'last_name'
    u.email = require_param 'email'
    u.phone = require_param 'phone'
    u.address = require_param 'address'
    u.description = ""

    if u.save 
      archive.log "new user: #{u.id}", @user
    else
      error "could not save user, errors: #{u.errors}"
    end

    redirect '/admin/users'

  when 'modify-user'
    type = require_param 'type'

    if type == "operator"
      u = Operator.get require_param 'id'
    else
      u = Contact.get require_param 'id'

      perms = []
      perms.push :disseminate if params['disseminate_perm'] == "on"
      perms.push :withdraw if params['withdraw_perm'] == "on"
      perms.push :peek if params['peek_perm'] == "on"
      perms.push :submit if params['submit_perm'] == "on"
      perms.push :report if params['report_perm'] == "on"

      u.permissions = perms
    end

    u.first_name = require_param 'first_name'
    u.last_name = require_param 'last_name'
    u.email = require_param 'email'
    u.phone = require_param 'phone'
    u.address = require_param 'address'

    if u.save 
      archive.log "updated user: #{u.id}", @user
    else
      error "could not update user, errors: #{u.errors}"
    end

    redirect '/admin/users'

  when 'change-user-password'
    u = User.get require_param "id"

    error 400 unless u.authenticate require_param("old_password")
    error 400 unless require_param("new_password") == require_param("new_password_confirm")

    u.encrypt_auth require_param("new_password")

    if u.save 
      archive.log "changed password for user: #{u.id}", @user
    else
      error "could not update user, errors: #{u.errors}"
    end 

    redirect '/admin/users'

  when 'delete-user'
    id = require_param 'id'
    u = User.get(id) or not_found
    u.deleted_at = Time.now

    if u.save 
      archive.log "delete user: #{u.id}", @user
    else
      error "could not delete user"
    end

    redirect '/admin/users'

  when 'make-admin-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_admin_contact = true

    if u.save 
      archive.log "made admin contact: #{u.id}", @user
    else
      error "could not save user, errors: #{u.errors}"
    end

    redirect '/admin/users'

  when 'make-tech-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_tech_contact = true

    if u.save 
      archive.log "made tech contact: #{u.id}", @user
    else
      error "could not save user, errors: #{u.errors}"
    end

    redirect '/admin/users'

  when 'unmake-admin-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_admin_contact = false

    if u.save 
      archive.log "unmade admin contact: #{u.id}", @user
    else 
      error "could not save user, errors: #{u.errors}"
    end

    redirect '/admin/users'

  when 'unmake-tech-contact'
    id = require_param 'id'
    u = Contact.get(id) or not_found
    u.is_tech_contact = false

    if u.save
      archive.log "unmade tech contact: #{u.id}", @user
    else
      error "could not save user, errors: #{u.errors}"
    end

    redirect '/admin/users'

  else raise "unknown task: #{params['task']}"
  end

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
    note = require_param 'note'
    error 400, "request submissions must include a note" unless note and note != ""

    @batch.packages.each do |package|
      type = require_param 'type'

      next if package.requests.first(:type => type, :status => :enqueued)
      next if package.events.first(:name => "reject")
      next if package.events.first(:name => "withdraw finished")

      r = Request.new

      r.type = type
      r.note = note
      r.is_authorized = false if type = r.type == :withdraw

      @user.requests << r
      r.agent = @user
      package.requests << r
      r.package = package

      r.save or error "cannot save request: #{r.errors.inspect}"
      package.log "#{r.type} request placed", :notes => "request id: #{r.id}", :agent => @user
    end

    redirect "/batches"
  end
end

get '/fda_logo' do
  File.read "public/FDA-colorLogo.png"
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

# op event comments
get '/events/:id' do |id|
  @e = Event.get(id)

  haml :event
end

post '/events/:id' do |id|
  require_param 'comment_text'

  e = Event.get(id)
  c = Comment.create :event => e, :agent => @user, :text => params['comment_text']

  redirect "/events/#{e.id}"
end
