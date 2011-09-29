module Daitss

  # Pobject represents a premis object containing common properties and behavior shared among premis files and premis bitstreams.
  class Pobject
    def initialize
      @object = nil
    end

    # process (extract and populate) the object characteristic extension inside the premis object
    def processObjectCharacteristicExtension(p, premis)
      # create an audio record if this premis object is an audio
      if aes = premis.find_first("aes:audioObject", NAMESPACES)
        @object = Audio.new
        @object.fromPremis aes
        p.audios << @object
        # create a text record if this premis object represents a text object
      elsif textmd = premis.find_first("txt:textMD", NAMESPACES)
        @object = Text.new
        @object.fromPremis textmd
        p.texts << @object
        # create an image record if this premis object represents an image
      elsif mix = premis.find_first("mix:mix", NAMESPACES)
        @object = Image.new
        @object.fromPremis mix
        p.images << @object
        # create a document record if this premis object represents a document
      elsif doc = premis.find_first("doc:doc/doc:document", NAMESPACES)
        @object = Document.new
        @object.fromPremis doc
        p.documents << @object
      end
    end

    # process (extract and populate) the format information inside the premis object
    def processFormats(p, premis, formats)
      # process all listed formats inside the premis object
      list = premis.find("premis:objectCharacteristics/premis:format", NAMESPACES)
      firstNode = true
      list.each do |node|
        # create a temporary format record with the info. from the premis
        newFormat = Format.new
        newFormat.fromPremis node

        # check if it was processed earlier.
        format = formats[newFormat.format_name]

        # otherwise, check if it's not already in the format table,
        format = Format.first(:format_name => newFormat.format_name) if format.nil?

        # use the new format record if the format name has not been seen before.
        format = newFormat if format.nil?

        # create an ObjectFormat record to associate this object record (either a datafile or a bitstream) to
        # the identified format record
        objectformat = ObjectFormat.new

        if (p.instance_of? Datafile)
          objectformat.datafile_id = p.id
          objectformat.bitstream_id = nil
        else
          objectformat.bitstream_id = p.id
          objectformat.datafile_id = nil
        end

        format.object_formats << objectformat
        formats[format.format_name] = format

        p.object_formats << objectformat

        # first format element is designated for the primary object (file/bitstream) format.
        # Subsequent format elements are used for format profiles
        if (firstNode)
          objectformat.setPrimary
          firstNode = false
        else
          objectformat.setSecondary
        end
        #objectformat.inspect
      end
      list = nil
    end
  end

end
