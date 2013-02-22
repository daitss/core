require 'daitss/proc/template'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/datafile'
require 'net/http'
require 'cgi'

require 'daitss/proc/datafile/actionplan'

module Daitss

  class DataFile

    # Create a migrated version of this datafile if the acitonplan dictates
    def migrate!
      transform :migrate
    end

    # Create a migrated version of this datafile if the acitonplan dictates
    def normalize!
      transform :normalize
    end

    def next_transformed_id df
      case df.id
      when /#{id}-(norm|mig)-(\d+)/ then "#{id}-#{$1}-#{$2.to_i + 1}"
      else raise "ill-formed datafile id: #{df.id}"
      end
    end

    def transform strategy

      source = case strategy
               when :migrate then migrated_version || self
               when :normalize then self
               else raise "unknown transformation strategy: #{strategy}"
               end

      ap_data = case strategy
                when :migrate then source.migration
                when :normalize then source.normalization
                else raise "unknown transformation strategy: #{strategy}"
                end
                      
      if ap_data
        xform_id = case strategy
                   when :migrate then ap_data['migration']
                   when :normalize then ap_data['normalization']
                   else raise "unknown transformation strategy: #{strategy}"
                   end
                         
        skip = skip_transformation_service xform_id, archive.skip_undefined

        unless skip
          begin
            agent_key, event_key = case strategy
                               when :normalize then ['normalize-agent', 'normalize-event']
                               else raise "unknown transformation strategy: #{strategy}"
                               end
  
            old, dest = case strategy
                    when :migrate
                      old = migrated_version
                      dest_id = old ? next_transformed_id(old) : "#{id}-mig-0"
                      dest = @wip.new_migrated_datafile dest_id
                      [old, dest]
                    when :normalize
                      old = normalized_version
                      dest_id = (old ? next_transformed_id(old) : "#{id}-norm-0")
                      dest = @wip.new_normalized_datafile dest_id
                      [old, dest]
                    else raise "unknown transformation strategy: #{strategy}"
                    end

            agent, event, data, ext = source.ask_transformation_service xform_id

            # fill in destination datafile
            dest.open('w') { |io| io.write data }
            dest['aip-path'] = File.join Wip::AIP_FILES_DIR, "#{dest.id}#{ext}"
            dest[agent_key] = fix_transformation_agent agent
            dest[event_key] = fix_transformation_event event, source, dest, strategy, ap_data
            dest["transformation-source"] = source.uri
            dest["transformation-strategy"] = strategy.to_s

            # make the old one obsolete
            old.obsolete! if old
          rescue => e
            dest.nuke! if dest
            raise e
          end
        end
      end

    end

    # skip the undefined transformation identifier if skip_undefined is true
    def skip_transformation_service xform_id, skip_undefined
      url_location =  archive.transform_url + '/transform/' + xform_id
      url = URI.parse url_location
      c = Curl::Easy.new url_location
      c.perform
      # check if we should skip transformation if there is no xform_id defined, i.e., 404 + ignore_404=true
      if c.response_code != 200 && skip_undefined
        true
      else
        false
      end
    end
    
    # submit file to either local (use HTTP GET) or remote (use HTTP POST) transformation to convert sip files according
    # to the transformation instruction returned from the action plan service.  Parse the xml output returned from 
    # the transformation to extract the detailed event and agent information.
    def ask_transformation_service xform_id
      doc = nil
      url_location =  archive.transform_url + '/transform/' + xform_id
      url = URI.parse url_location
      # ask for the main doc with the link, event, agent
      if (archive.remote_transform)
        c = Curl::Easy.new url_location
        c.multipart_form_post = true
        data = Curl::PostField.file 'file', data_file
        c.http_post data
        c.response_code == 200 or c.error("bad status")   
        doc = XML::Document.string c.body_str     
      else
        path = File.expand_path data_file
        c = Curl::Easy.new "#{url_location}?location=file:#{path}"
        c.perform
        c.response_code == 200 or c.error("bad status")   
        doc = XML::Document.string c.body_str
      end
      
      agent = doc.find_first('//P:agent', NS_PREFIX)
      event = doc.find_first('//P:event', NS_PREFIX)
      unless doc.find_first('//P:links/P:link', NS_PREFIX).nil?
        link = url + doc.find_first('//P:links/P:link', NS_PREFIX).content
     
        # ask for the data from the link
        req = Net::HTTP::Get.new link.request_uri

        res = Net::HTTP.start(url.host, url.port) do |http|
          http.read_timeout = Archive.instance.http_timeout
          http.request req
        end

        res.error! unless Net::HTTPSuccess === res
        data = res.body
        ext = File::extname(link.request_uri)

        # return everything
        [agent, event, data, ext]
      else
        # no link, return only agent and event
        [agent, event, nil, nil]
      end
    end

    def fix_transformation_event node, source, dest, strategy, ap_data
      d = XML::Document.new
      d.root = d.import node

      # attach objects
      event_uri = "#{dest.uri}/event/#{strategy}/#{next_event_index strategy}"
      d.find_first("//P:eventIdentifierValue", NS_PREFIX).content = event_uri
      d.find_first("//P:eventType", NS_PREFIX).content = strategy.to_s

      date_time = d.find_first("//P:eventDateTime", NS_PREFIX)

      detail = XML::Node.new 'eventDetail'
      detail << ap_data.map { |k,v| "#{k}: #{v}" }.join("\n")
      date_time.next = detail

      linking_objects = [%Q{
      <linkingObjectIdentifier>
        <linkingObjectIdentifierType>URI</linkingObjectIdentifierType>
        <linkingObjectIdentifierValue>#{dest.uri}</linkingObjectIdentifierValue>
        <linkingObjectRole>outcome</linkingObjectRole>
      </linkingObjectIdentifier>
      },
      %Q{
      <linkingObjectIdentifier>
        <linkingObjectIdentifierType>URI</linkingObjectIdentifierType>
        <linkingObjectIdentifierValue>#{source.uri}</linkingObjectIdentifierValue>
        <linkingObjectRole>source</linkingObjectRole>
      </linkingObjectIdentifier>
      }].each do |xml|
        node = d.import XML::Document.string(xml).root
        d.root << node
      end

      d.root
    end

    def fix_transformation_agent node
      d = XML::Document.new
      d.root = d.import node
      d.root
    end

  end

end
