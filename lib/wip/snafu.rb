require 'wip'

class Wip

  def snafu?
    check_dead
    tags.has_key? 'snafu'
  end

  def snafu
    check_dead
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
    tags.delete 'snafu' if snafu?
  end

  private

  def check_dead

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
