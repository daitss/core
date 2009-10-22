require 'yaml'

module Config
  
  Service = {}
  
  def load file
     Service.merge! YAML.load open(file) { |io| io.read }
  end
  
  module_function :load
end