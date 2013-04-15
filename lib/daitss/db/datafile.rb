require 'data_mapper'
require 'daitss/db/pobject'

module Daitss

  # constant for representation id
  REP_CURRENT = "representation/current"
  REP_0 = "representation/original"
  REP_NORM = "representation/normalized"

  # constant for datafile origin
  ORIGIN_ARCHIVE = "ARCHIVE"
  ORIGIN_DEPOSITOR = "DEPOSITOR"
  ORIGIN_UNKNOWN = "UNKNOWN"
  Origin = [ ORIGIN_ARCHIVE, ORIGIN_DEPOSITOR, ORIGIN_UNKNOWN ]

  MAX_CREATING_APP = 255
  
  class Datafile < Pobject
    include DataMapper::Resource

    property :id, String, :key => true, :length => 100
    property :size, Integer, :min => 0, :max => 2**63-1, :required => true
    property :create_date, DateTime
    property :origin, String, :length => 10, :required => true # :default => ORIGIN_UNKNOWN,
    # the value of the origin is validated by the validateOrigin method
    #validates_with_method :origin, :validateOrigin

    property :original_path, String, :length => (0..255), :required => true
    # map from package_path + file_title + file_ext
    property :creating_application, String, :length => (0..MAX_CREATING_APP)
    property :is_sip_descriptor, Boolean, :default => false

    property :r0, Boolean, :default  => false
    #true if this datafile is part of the original representation
    property :rn, Boolean, :default  => false
    #true if this datafile is part of the normalized representation
    property :rc, Boolean, :default  => false
    #true if this datafile is part of the current representation

    belongs_to :intentity

    has 0..n, :bitstreams, :constraint=>:destroy # a datafile may contain 0-n bitstream(s)
    has n, :datafile_severe_element, :constraint=>:destroy
    has 0..n, :documents, :constraint => :destroy
    has 0..n, :texts, :constraint => :destroy
    has 0..n, :audios, :constraint => :destroy
    has 0..n, :images, :constraint => :destroy
    has 0..n, :message_digest, :constraint => :destroy
    has 0..n, :object_formats, :constraint=>:destroy # a datafile may have 0-n file_formats
    has 0..n, :broken_links, :constraint=>:destroy # if there is missing links in the datafiles (only applies to xml)
   
    def check_errors
      unless self.valid?
        bigmessage = self.errors.full_messages.join "\n" 
        raise bigmessage unless bigmessage.empty?
      end
      
      bitstreams.each {|obj| obj.check_errors}    
      
      invalids = (datafile_severe_element ).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?
          
      documents.each {|obj| obj.check_errors }       

      invalids = (texts ).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?

      invalids = (audios ).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?

      invalids = (images ).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?       

      invalids = (message_digest).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?  

      invalids = (broken_links).reject {|obj| obj.valid? }    
      bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
      raise bigmessage unless bigmessage.empty?
        
      object_formats.each {|obj| obj.check_errors }                        
    end
#
    # tests to see if string passed in has valid utf8 encoding
    def is_utf8?(str)
      isutf8 = true
         begin
          str.unpack('U'*str.length)  # check for utf-8 encoding violations, either introduced or in the data
         rescue
          isutf8 = false
         end
      isutf8
    end
    
    #  our database is set to utf8 encoding. we must ensure strings for insert  meet this condition.
    # this method does:
    # 1. limits content to a maximun size.
    # 2  then if the truncation on the right happened to fall
    #   in the middle of a multibyte utf8 character it lops off a byte at a time upto 5.
    # 3. finally it tests the string for valid utf8 and if not converts the string to hexadecimal characters.
    #
    def utf8_trunc(content)
       if     content.length > MAX_CREATING_APP
          # truncate all characters exceeding MAX_CREATING_APP(255) bytes which is the maximum size for the creating application name.
         content = content.slice(0, MAX_CREATING_APP) # has the potential to break utf8,if @255 there is a multibyte char
       end
       utf8len = content.length
       utf8str = content
       while  utf8len > content.length - 5

         if is_utf8?(utf8str) 
	   break
	 else
           utf8len -= 1
	   utf8str = content.slice(0,utf8len)
	 end
       
       end 

      if ! is_utf8?(utf8str)
          utf8str =  utf8str.each_byte.map { |b| b.to_s(16) }.join   # conv to hex, doubles the length
         if     utf8str.length > MAX_CREATING_APP
         #truncate all chars exceeding MAX_CREATING_APP(255) bytes which is the maximum size for the creating application name.
           utf8str = utf8str.slice(0, MAX_CREATING_APP)
         end
      end

       utf8str
    end


    def fromPremis(premis, formats, sip_descriptor_ownerid)
      id = premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
      attribute_set(:id, id)
      attribute_set(:size, premis.find_first("premis:objectCharacteristics/premis:size", NAMESPACES).content)

      # creating app. info
      node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:creatingApplicationName", NAMESPACES)
      if node
        content = utf8_trunc(node.content)
        attribute_set(:creating_application, content) 
       end
                    
      node = nil
      
      node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:dateCreatedByApplication", NAMESPACES)
      attribute_set(:create_date, node.content) if node
     
      node = nil
     
      node = premis.find_first("premis:originalName", NAMESPACES)
      attribute_set(:original_path, node.content) if node
      node = nil
      
      attribute_set(:is_sip_descriptor, true) if id == sip_descriptor_ownerid
      is_sip_descriptor = nil
            
      # process format information
      processFormats(self, premis, formats)
 
      # process fixity information
      fixities = premis.find("premis:objectCharacteristics/premis:fixity", NAMESPACES)
      fixities.each do |fixity|
        messageDigest = MessageDigest.new
        messageDigest.fromPremis(fixity)
        self.message_digest << messageDigest
      end
      fixities = nil
            
      # process premis ObjectCharacteristicExtension
      node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
      if (node)
        processObjectCharacteristicExtension(self, node)
        @object.bitstream_id = nil
      end
      node = nil
      
      # process inhibitor if there is any
      node = premis.find_first("premis:objectCharacteristics/premis:inhibitors", NAMESPACES)
      if (node)
        inhibitor = Inhibitor.new
        inhibitor.fromPremis(node)
        # use the existing inhibitor record in the database if we have seen this inhibitor before
        existingInhibitor = Inhibitor.first(:name => inhibitor.name, :target => inhibitor.target)

        dfse = DatafileSevereElement.new
        self.datafile_severe_element << dfse
        if existingInhibitor
          existingInhibitor.datafile_severe_element << dfse
        else
          inhibitor.datafile_severe_element << dfse
        end
      end
      node = nil
      
    end

    # validate the datafile Origin value which is a daitss defined controlled vocabulary
    def validateOrigin
      unless Origin.include?(@origin)
        raise "value #{@origin} is not a valid origin value" 
      end
    end

    # derive the datafile origin by its association to representations r0, rc
    def setOrigin
      # if this datafile is in r(c) or r(n) but not in r(0), it is created by the archive, otherwise it is submitted by depositor.
      if (( @rc || @rn) && !@r0)
        attribute_set(:origin, ORIGIN_ARCHIVE)
      else
        attribute_set(:origin, ORIGIN_DEPOSITOR)
      end
      validateOrigin
    end

    # set the representation (r0, rn, rc) which contains this datafile
    def setRepresentations(rep_id)
      if (rep_id.include? REP_0)
        attribute_set(:r0, true)
      elsif  (rep_id.include? REP_CURRENT)
        attribute_set(:rc, true)
      elsif (rep_id.include? REP_NORM)
        attribute_set(:rn, true)
      end
    end

  end

end
