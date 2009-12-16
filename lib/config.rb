require 'yaml'

CONFIG = {}

def CONFIG.load file
  merge! YAML.load open(file) { |io| io.read }
end
