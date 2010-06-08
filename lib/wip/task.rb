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

  def done?

    if not(running?) and tags.has_key?('done')
      Time.parse tags['done'] rescue false
    else
      false
    end

  end

  def done!
    tags['done'] = Time.now.xmlschema 4
  end

  def start_task

    case task

    when :ingest

      start do |wip|

        begin

          #Daitss::CONFIG.load_rjb
          require 'wip/ingest'
          DataMapper.setup :default, Daitss::CONFIG['database-url']

          sip = SubmittedSip.first :ieid => wip.id

          # ingest start event
          event = OperationsEvent.new :event_name => 'Ingest Started'
          event.operations_agent = Program.system_agent
          event.submitted_sip = sip
          event.save or raise "cannot save op event for ingest"

          wip.ingest!
          wip.done!
          FileUtils.rm_r wip.path # XXX move to safe dotfile dir then delete?

          # ingest complete event
          event = OperationsEvent.new :event_name => 'Ingest Complete'
          event.operations_agent = Program.system_agent
          event.submitted_sip = sip
          event.save or raise "cannot save op event for ingest"
        rescue => e
          wip.snafu = e

          # ingest snafu event
          event = OperationsEvent.new :event_name => 'Ingest Snafu'
          event.operations_agent = Program.system_agent
          event.submitted_sip = sip
          event.save or raise "cannot save op event for ingest"
        end

      end

    else raise "unknown task #{task ? task : task.inspect}, cannot start wip"
    end

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
