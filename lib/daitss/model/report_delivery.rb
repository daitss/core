require 'data_mapper'
require 'daitss/model/package'

module Daitss
  class ReportDelivery
    include DataMapper::Resource

    property :id, Serial, :key => true
    property :mechanism, Enum[:email, :ftp], :default => :email
    property :type, Enum[:reject, :ingest], :default => :ingest

    belongs_to :package
  end
end
