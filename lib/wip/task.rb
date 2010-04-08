require 'wip/process'
require 'wip/snafu'

class Wip

  def task

    if tags.has_key? 'task'
      tags['task'].to_sym
    end

  end

  def task= t
    tags['task'] = t.to_s
  end

  def task_complete
    tags['task-complete'] = Time.now.xmlschema
  end

  def task_complete?
    tags.has_key? 'task-complete'
  end

  def start_task

    case task

    when :ingest

      start do |wip|
        require 'wip/ingest'
        DataMapper.setup :default, CONFIG['database-url']

        begin
          wip.ingest!
          wip.task_complete
        rescue => e
          wip.snafu = e
        end

      end

    else raise "cannot start #{task}, unknown"
    end

  end

end
