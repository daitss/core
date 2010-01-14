require 'spec/expectations'

Before do
  DataMapper.auto_migrate!
end