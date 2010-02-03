require 'sinatra'
require 'workspace'
require 'wip/process'
require 'sass'

raise "no workspace" unless ENV['WORKSPACE']

helpers do

  def state wip

    if wip.done?
      'done'
    elsif wip.running?
      'running'
    else
      'idle'
    end

  end

end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do
  @workspace = Workspace.new ENV['WORKSPACE']
  haml :index
end

get '/:id' do |id|
  workspace = Workspace.new ENV['WORKSPACE']

  if workspace.has_wip? id
    @wip = workspace[id]
    haml :wip
  else
    not_found "wip #{id} not found"
  end

end

post '/:id' do |id|
  workspace = Workspace.new ENV['WORKSPACE']
  error 400, "state param missing" unless params['state']

  if workspace.has_wip? id
    @wip = workspace[id]

    case params['state']
    when 'start' then @wip.start { sleep 10 }
    when 'stop' then @wip.stop
    else error 400, "only valid states are start and stop"
    end

    redirect @wip.id
  else
    not_found "wip #{id} not found"
  end

end
