require 'template'
require 'service/error'

module Service

  module Transform

    def migrated_src
      transform_src 'migration'
    end

    def normalized_src
      transform_src 'normalization'
    end

    private

    def transform_src type

      file_id = metadata.find do |key, doc| 
        event = doc.find_first "//P:event[P:eventType = '#{type}']", NS_PREFIX
        related_object_id = event.find_first "P:relatedObjectIdentifier/P:relatedObjectIdentifierValue". NS_PREFIX
        related_object_id.content
      end

      wip.files.find { |f| f.id == file_id }
    end

  end

end
