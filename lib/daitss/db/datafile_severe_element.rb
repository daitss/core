module Daitss

  class DatafileSevereElement
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :datafile_id, String, :length => 100
    # property :severe_element_id, Serial
    belongs_to :datafile
    belongs_to :severe_element

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
      puts "#{severe_element.errors.to_a} error encountered while saving #{severe_element.inspect} " unless severe_element.valid?
    end
  end

end
