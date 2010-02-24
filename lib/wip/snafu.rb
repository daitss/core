require 'wip'

class Wip

  def snafu?
    tags.has_key? 'snafu'
  end

  def snafu
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

end
