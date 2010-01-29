require 'template'
require 'time'

def event options={}
  options[:linking_objects] ||= []
  options[:linking_agents] ||= []
  template_by_name('premis/event').result binding
end

def agent options={}
  template_by_name('premis/agent').result binding
end

def relationship options={}
  options[:related_objects] ||= []
  options[:related_events] ||= []
  template_by_name('premis/object/relationship').result binding
end
