require 'template'
require 'time'

def event options={}
  options[:related_objects] ||= []
  options[:related_agents] ||= []
  template_by_name('premis/event').result binding
end

def agent options={}
  template_by_name('premis/agent').result binding
end

