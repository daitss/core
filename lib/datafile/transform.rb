require 'template'
require 'datafile'
require 'net/http'
require 'cgi'

require 'datafile/actionplan'

class DataFile

  # Create a migrated version of this datafile if the acitonplan dictates
  def migrate!
    source = (migrated_version || self)
    transformation_url = source.migration

    if transformation_url
      old_df = migrated_version
      mig_id = old_df ? next_transformed_id(old_df) : "#{id}-mig-0"
      mig_df = @wip.new_migrated_datafile mig_id
      transform_df source, mig_df, old_df, transformation_url
      mig_df['transformation-strategy'] = 'migrate'
    end

  end

  # Create a migrated version of this datafile if the acitonplan dictates
  def normalize!
    source = self
    transformation_url = source.normalization

    if transformation_url
      old_df = normalized_version
      norm_id = old_df ? next_transformed_id(old_df) : "#{id}-norm-0"
      norm_df = @wip.new_normalized_datafile norm_id
      transform_df source, norm_df, old_df, transformation_url
      norm_df['transformation-strategy'] = 'normalize'
    end

  end

  def next_transformed_id df
    case df.id
    when /#{id}-(norm|mig)-(\d+)/ then "#{id}-#{$1}-#{$2.to_i + 1}"
    else raise "ill formed datafile id: #{df.id}"
    end
  end

  def transform_df source_df, dest_df, old_df, transformation_url

    # perform transformation
    data, ext = source_df.transform transformation_url

    # fill in destination datafile
    dest_df.open('w') { |io| io.write data }
    dest_df['aip-path'] = "#{dest_df.id}#{ext}"
    dest_df['transformation-agent'] = transformation_url
    dest_df['transformation-source'] = source_df.uri

    # make the old one obsolete
    old_df.obsolete! if old_df
  rescue
    dest_df.nuke!
    raise
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

    links = doc.find('//P:links/P:link', NS_PREFIX).map do |node|
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

    end.first

  end

end
