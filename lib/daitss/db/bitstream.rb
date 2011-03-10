require 'data_mapper'

require 'daitss/db/pobject'

module Daitss

  class Bitstream < Pobject
    include DataMapper::Resource
    property :id, String, :key => true, :length => 100
    property :size, Integer

    belongs_to :datafile # a bitstream is belong to a datafile

    has 0..n, :documents, :constraint => :destroy
    has 0..n, :texts, :constraint => :destroy
    has 0..n, :audios, :constraint => :destroy
    has 0..n, :images, :constraint => :destroy

    has 0..n, :object_formats, :constraint => :destroy # a bitstream may have 0-n formats

    def check_errors
      raise "cannot save bitstream #{self.errors.to_s}" unless self.valid?
          
      documents.each {|obj| obj.check_errors }       
       
      invalids = (texts).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?

      invalids = (audios ).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?

      invalids = (images ).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty? 
    
      object_formats.each {|obj| obj.check_errors }               
    end
      
    def fromPremis(premis, formats)
      attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)

      # process premis ObjectCharacteristicExtension
      node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
      if (node)
        processObjectCharacteristicExtension(self, node)
        @object.datafile_id = :null
      end

      # process format information
      processFormats(self, premis, formats)
    end

    # delete this bitstream record and all its children from the database
    before :destroy do
      # delete all metadata associated with this datafile
      # texts = Text.all(:bitstream_id => @id)
      #   texts.each {|text| text.destroy}
      #   audios = Audio.all(:bitstream_id => @id)
      #   audios.each {|audio| audio.destroy}
      #   images = Image.all(:bitstream_id => @id)
      #   images.each {|image| image.destroy}
      #   docs = Document.all(:bitstream_id => @id)
      #   docs.each {|doc| doc.destroy}
    end

  end

end
