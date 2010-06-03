app_path = File.join File.dirname(__FILE__), 'statusecho'
require app_path

set :env, :production
disable :run, :reload

run Sinatra::Application
