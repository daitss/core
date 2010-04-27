require 'sinatra'
require 'haml'
require 'sass'

require 'workspace'
require 'wip/process'
require 'wip/state'
require 'wip/json'
require 'daitss/config'

configure do
  raise "no configuration" unless ENV['CONFIG']
  Daitss::CONFIG.load ENV['CONFIG']

  set :workspace, Workspace.new(Daitss::CONFIG['workspace'])
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

# index
get '/' do
  haml :index
end

# workspace resource ######

get '/workspace' do

  if request.accept.include? 'application/json'
    settings.workspace.to_json
  else
    haml :workspace
  end

end

post '/workspace' do

  case params['task']
  when 'start'
    startable = settings.workspace.reject { |w| w.running? || w.done? }
    startable.each { |wip| wip.start_task }

  when 'stop'
    stoppable = settings.workspace.select { |w| w.running? }
    stoppable.each { |wip| wip.stop }

  when 'unsnafu'
    unsnafuable= settings.workspace.select { |w| w.snafu? }
    unsnafuable.each { |wip| wip.unsnafu! }

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
    FileUtils::mv wip.path, params['path']
    redirect '/'

  when nil, '' then raise 400, 'parameter task is required'
  else error 400, "unknown command: #{params['task']}"
  end

  redirect wip.id
end
