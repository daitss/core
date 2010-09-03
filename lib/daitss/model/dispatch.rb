# SMELL this could be moved into Request OOP style
# TODO: move to methods to wip class

require 'daitss/proc/wip'
require 'uri'
require 'daitss/config'
require 'daitss/proc/workspace'
require 'daitss/archive'

class Dispatch

  DISSEMINATE_DROP_PATH = "/tmp/disseminations/"

  # creates a dissemination "sub-wip" in the workspace

  def self.dispatch_request ieid, type
    ws_path = Archive.new.workspace.path
    prefix_uri = Daitss::CONFIG['uri-prefix']
    path = File.join(ws_path, ieid.to_s)
    wip = Wip.new path, prefix_uri

    case type

    when :disseminate
      wip.tags["drop-path"] = DISSEMINATE_DROP_PATH
      wip.tags["dissemination-request"] = Time.now.to_s
    when :withdraw
      wip.tags["withdrawal-request"] = Time.now.to_s
    when :peek
      wip.tags["peek-request"] = Time.now.to_s
    else
      raise "Unknown request type: #{type}"
    end

    return path
  end

  def self.wip_exists? ieid
    ws_path = Archive.new.workspace.path
    File.exists? File.join(ws_path, ieid.to_s)
  end

end
