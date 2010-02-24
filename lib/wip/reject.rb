require 'wip'

class Wip

  def reject?
    tags.has_key? 'reject'
  end

  def reject
    tags['reject']
  end

  def reject= e
    msg = StringIO.new
    msg.puts Time.now.xmlschema 4
    msg.puts
    msg.puts e.message
    tags['reject'] = msg.string
  end

end
