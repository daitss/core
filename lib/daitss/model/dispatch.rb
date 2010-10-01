# SMELL this could be moved into Request OOP style
# TODO: move to methods to wip class

require 'daitss/proc/wip'
require 'uri'
require 'daitss/proc/workspace'
require 'daitss/archive'

class Dispatch

  # TODO this needs to be in the config file or part of the data-dir
  DISSEMINATE_DROP_PATH = "/tmp/disseminations/"

  # creates a dissemination "sub-wip" in the workspace

  def self.dispatch_request ieid, type
    ws_path = Daitss.archive.workspace.path
    prefix_uri = Daitss.archive.uri_prefix
    path = File.join(ws_path, ieid.to_s)
    wip = Wip.new path

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
    ws_path = Daitss.archive.workspace.path
    File.exists? File.join(ws_path, ieid.to_s)
  end

end
