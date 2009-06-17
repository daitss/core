require 'rack'

# validation & provenance
$:.unshift File.join('..', 'validate-service', 'lib')
require File.join('..', 'validate-service', 'validation')
require File.join('..', 'validate-service', 'provenance')

# description
$:.unshift File.join('..', 'describe', 'lib')
require File.join('..', 'describe', 'describe')

# transformation
$:.unshift File.join('..', 'transform', 'lib')
require File.join('..', 'transform', 'transform')

test_stack = Rack::Builder.new do
  
   use Rack::CommonLogger
   use Rack::ShowExceptions
   
   map "/validation" do
     use Rack::Lint
     run Validation.new
   end
   
   map "/provenance" do
     use Rack::Lint
     run Provenance.new
   end

   map "/description" do
     use Rack::Lint
     run Describe.new
   end

   map "/transformation" do
     use Rack::Lint
     run Transform.new
   end
   
end

thin = Rack::Handler::Thin
thin.run test_stack, :Port => '7000'
