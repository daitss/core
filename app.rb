require 'sinatra'
require 'haml'
require 'sass'

require 'workspace'
require 'wip/process'
require 'wip/state'
require 'wip/json'
require 'config'

configure do

  # workspace
  raise "no workspace" unless ENV['WORKSPACE']
  raise "#{ENV['WORKSPACE']} is not a directory" unless File.directory? ENV['WORKSPACE']
  WORKSPACE = Workspace.new ENV['WORKSPACE']

  # configuration
  raise "no configuration" unless ENV['CONFIG']
  CONFIG.load ENV['CONFIG']
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do

  if request.accept.include? 'application/json'
    WORKSPACE.to_json
  else
    haml :index
  end

end

post '/' do

  case params['task']
  when 'start'
    startable = WORKSPACE.reject { |w| w.running? || w.done? }
    startable.each { |wip| wip.start_task }
    
  when 'stop'
    stoppable = WORKSPACE.select { |w| w.running? }
    stoppable.each { |wip| wip.stop }

  when 'unsnafu'
    unsnafuable= WORKSPACE.select { |w| w.snafu? }
    unsnafuable.each { |wip| wip.unsnafu! }

  when nil, '' then error 400, "parameter task is required"
  else error 400, "unknown command: #{params['task']}"
  end

  redirect '/'
end

get '/:id' do |id|
  @wip = WORKSPACE[id] or not_found

  if request.accept.include? 'application/json'
    @wip.to_json
  else
    haml :wip
  end

end

post '/:id' do |id|
  wip = WORKSPACE[id] or not_found

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
