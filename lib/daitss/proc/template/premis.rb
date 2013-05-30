require 'time'

require 'daitss'
require 'daitss/proc/template'

module Daitss

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

  def system_agent_spec
    pre = Daitss.archive.uri_prefix
    version = Daitss::VERSION

    {
      :id => "#{pre}system-#{version}",
      :name => "daitss system (#{version})",
        :type => 'software'
    }
  end

  def system_agent
    agent system_agent_spec
  end

  def ingest_event package

    spec = {
      :id => "#{package.uri}/event/ingest",
      :type => 'ingest',
      :outcome => 'success',
      :linking_objects => [ package.uri ],
      :linking_agents => [ system_agent_spec[:id] ]
    }

    event spec
  end

  def disseminate_event package, index

    spec = {
      :id => "#{package.uri}/event/disseminate/#{index}",
      :type => 'disseminate',
      :outcome => 'success',
      :linking_objects => [ package.uri ],
      :linking_agents => [ system_agent_spec[:id] ]
    }

    event spec
  end

  def refresh_event package, index

    spec = {
      :id => "#{package.uri}/event/refresh/#{index}",
      :type => 'refresh',
      :outcome => 'success',
      :linking_objects => [ package.uri ],
      :linking_agents => [ system_agent_spec[:id] ]
    }

    event spec
  end
  
  def withdraw_event package

    spec = {
      :id => "#{package.uri}/event/withdraw",
      :type => 'withdraw',
      :outcome => 'success',
      :linking_objects => [ package.uri ],
      :linking_agents => [ system_agent_spec[:id] ]
    }

    event spec
  end

  # event for datafile
  def redup_event df, detail

    spec = {
      :id => "#{df.uri}/event/redup",
      :type => 'redup',
      :outcome => 'success',
      :detail => detail,
      :linking_objects => [ df.uri ],
      :linking_agents => [ system_agent_spec[:id] ]
    }

    event spec
  end

end
