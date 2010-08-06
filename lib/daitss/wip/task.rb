require 'wip/process'
require 'wip/snafu'

class Wip

  TASK_INGEST = :ingest
  TASK_DISSEMINATE = :disseminate

  def task

    if tags.has_key? 'task'
      tags['task'].to_sym
    end

  end

  def task= t
    tags['task'] = t.to_s
  end

  def stop
    kill
    tags['stop'] = Time.now.xmlschema
  end

  def stopped?
    tags.has_key? 'stop'
  end

  def unstop
    tags.delete 'stop'
  end

end
