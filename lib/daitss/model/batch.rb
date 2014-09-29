require 'data_mapper'

require 'daitss/archive'
require 'daitss/model/package'

module Daitss

  class Batch
    include DataMapper::Resource
    property :id, String, :key => true

    has n, :batch_assignments
    has n, :packages, :through => :batch_assignments
    
    def size_in_bytes
      size = 0
      self.packages.each do |p|
        size += p.sip.size_in_bytes
      end
      size
    end
    
    def submitted_datafiles
      num = 0
      self.packages.each do |p|
        num += p.sip.submitted_datafiles
      end
      num
    end
    
  end

  class BatchAssignment
    include DataMapper::Resource

    belongs_to :batch, :key => true
    belongs_to :package, :key => true
  end
end
