require 'curb'

class Curl::Easy

  def error msg
    sio = StringIO.new
    sio.puts msg
    sio.puts "#{self.url}: #{self.response_code}"
    sio.puts self.body_str if self.body_str
    raise sio.string
  end

end
