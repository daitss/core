require 'data_mapper'

require 'daitss/archive'
require 'daitss/model/package'

module Daitss

  class Batch
    include DataMapper::Resource
    property :id, String, :key => true

    has n, :batch_assignments
    has n, :packages, :through => :batch_assignments
    
    # helper methods - calculating the size and number of files is a best guess based on available package information
    # since batches can contain packages that errored out, rejected or are simply missing information. ex. daitss1 sips vs daitss2 sips
    def size_in_bytes
      size = 0
      self.packages.each do |p|
        size += p.sip.size_in_bytes || 0
      end
      size
    end
    
    def num_datafiles
      num = 0
      self.packages.each do |p|
        num += p.sip.number_of_datafiles || p.sip.submitted_datafiles
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
