$:.unshift File.join('..', 'validate-service', 'lib')
require File.join('..', 'validate-service', 'server')

map '/validatioin' do
  run Validation
end
