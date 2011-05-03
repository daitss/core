require 'dm-core'

require 'daitss/model/agent'
require 'daitss/model/package'
require 'daitss/model/comment'

module Daitss

  class Event
    include DataMapper::Resource

    property :id, Serial, :key => true
    property :name, String, :required => true, :index => true
    property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
    property :notes, Text, :length => 2**32-1
    property :outcome, String, :default => "N/A"

    belongs_to :agent
    belongs_to :package
    has n, :comments
  end

  def polite_name
    name.gsub 'snafu', 'error'
  end

end
