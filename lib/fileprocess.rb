require 'service/error'

module FileProcess

  def process!

    begin
      describe! unless described?
      plan! unless planned?

      transformations.each do |t|
        t.perform!

        t.data do |io, fname|
          new_file = @aip.add_file io, fname
          transform_md = t.metadata
          transform_md.fix_premis_ids! @aip
          md_id = new_file.add_md :digiprov, transform_md
          new_file.add_admid_ref md_id
          
          # get the event id and type
          doc = md_for_id md_id
          t_event = {
            :type => doc.find_first("/premis:premis/premis:event/premis:eventIdentifier/premis:eventIdentifierType", NS_MAP).content.strip,
            :value => doc.find_first("/premis:premis/premis:event/premis:eventIdentifier/premis:eventIdentifierValue", NS_MAP).content.strip
          }
          new_file.describe! t_event unless new_file.described?
        end

      end

    rescue Service::Error => e
      t = template_by_name 'per_file_error'
      s = t.result binding
      error_doc = XML::Parser.string(s).parse
      add_md :digiprov, error_doc
    end

  end

end
