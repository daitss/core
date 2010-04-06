require 'template'
require 'datafile'
require 'net/http'
require 'cgi'

class DataFile

  # Create a migrated version of this datafile if the acitonplan dictates
  def migrate!
    source = (migrated_version || self)
    old_df = migrated_version
    mig_df = new_migrated_datafile (old_df ? next_transformed_id df : "#{id}-mig-0")
    transformation_url = source.migration
    transform_df source, mig_df, old_df, transformation_url
  end

  # Create a migrated version of this datafile if the acitonplan dictates
  def normalize!
    source = self
    old_df = normalized_version
    norm_df = new_normalized_datafile (old_df ? next_transformed_id df : "#{id}-norm-0")
    transformation_url = source.normalization
    transform_df source, norm_df, old_df, transformation_url
  end

  private

  def next_transformed_id df
    case df.id
    when /#{id}-(norm|mig)-(\d+)/ then "#{id}-#{$1}-#{$2.to_i + 1}"
    else raise "ill formed datafile id: #{df.id}"
    end
  end

  def transform_df source_df, dest_df, old_df, transformation_url

    if transformation_url

      begin
        # perform transformation
        data, ext = source.transform transformation_url

        # fill in destination datafile
        dest_df.open('w') { |io| io.write data }
        dest_df['extension'] = ext
        dest_df['aip-path'] = "#{dest_df.id}#{extension}"
        dest_df['transformation-url'] = transformation_url
        dest_df['transformation-source'] = source.uri

        # make the old one obsolete
        old_df.obsolete! if old_df
      rescue
        new_df.nuke
        raise
      end

    end

  end

  def transform url
    url = URI.parse url
    req = Net::HTTP::Get.new url.path
    req.form_data = { 'location' => "file:#{File.expand_path datapath}" }

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end


    doc = case res
          when Net::HTTPSuccess then XML::Document.string(res.body)
          else res.error!
          end

    links = doc.find('/links/link').map do |node|
      link = node.content
      url + link
    end

    raise "no transformations occurred" if links.empty?

    links.map do |link|
      req = Net::HTTP::Get.new link.path

      res = Net::HTTP.start(url.host, url.port) do |http|
        http.read_timeout = Daitss::CONFIG['http-timeout']
        http.request req
      end

      case res
      when Net::HTTPSuccess then [res.body, File::extname(link.path)]
      else res.error!
      end

    end

  end

end
