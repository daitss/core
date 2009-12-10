require 'service/error'

module FileProcess

  def process!

    begin
      describe! unless described?
      # TODO migrate the file, with proper transform event, add to new r(c)
      m = migration
      if m
        # TODO do the transformation
        # TODO add the data as a new file to the aip
        # TODO add transformation metadata to the new file
        #
      end
      # TODO normalize the file, with proper transform event, add to new r(norm)
    rescue Service::Error => e
      @metadata['processing-error'] = e
    end

  end

end
