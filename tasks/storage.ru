lib_path = File.join File.dirname(__FILE__), '..', 'var', 'services', 'storage', 'lib'
$LOAD_PATH.unshift lib_path
require 'app'

set :env, :production
disable :run, :reload

silo_root = File.expand_path(File.join(File.dirname(__FILE__), '..', 'var', 'silo'))
set :silo_root, silo_root

run Sinatra::Application
