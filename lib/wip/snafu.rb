require 'wip'

class Wip

  def snafu?
    make_dead_snafu
    tags.has_key? 'snafu'
  end

  def snafu
    make_dead_snafu
    tags['snafu']
  end

  def snafu= e
    msg = StringIO.new
    msg.puts Time.now.xmlschema 4
    msg.puts
    msg.puts e.message
    msg.puts
    msg.puts e.backtrace
    tags['snafu'] = msg.string
  end

  def unsnafu!

    if snafu?
      tags.delete 'snafu'
      tags.delete 'process'
    else
      raise "cannot unsnafu a non-snafu package"
    end

  end

  private

  def make_dead_snafu

    unless tags.has_key? 'snafu'

      pid, ptime = process

      if !running? and pid

        begin
          raise "dead process #{pid} #{ptime.xmlschema}"
        rescue => e
          self.snafu = e
          tags.delete 'process'
        end

      end

    end

  end

end
