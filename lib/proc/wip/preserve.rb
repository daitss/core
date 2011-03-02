require 'proc/wip/journal'
require 'service/xml_res'
require 'proc/datafile/describe'
require 'proc/datafile/obsolete'
require 'proc/datafile/transform'

class Wip

  def preserve

    # describe and preserve original_files
    original_datafiles.each do |df|

      step("describe-migrate-normalize-#{df.id}") do
        df.describe!
        df.migrate!
        df.normalize!
      end

    end

    # describe transformed files
    tfs = (migrated_datafiles + normalized_datafiles).reject { |df| df.obsolete? }
    tfs.each { |df| step("describe-#{df.id}") { df.describe! } }

    # xmlresolve this wip
    step('xml-resolution') do
      xmlres = XmlRes.new
      xmlres.put_collection id

      all_datafiles.select(&:xmlresolution).each do |df|
        event, agent = xmlres.resolve_file(df.data_file, df.uri)
        df['xml-resolution-event'] = event
        df['xml-resolution-agent'] = agent
      end

      xmlres.save_tarball xmlres_file
    end

  end

  def original_representation
    original_datafiles
  end

  def current_representation
    original_datafiles.map { |odf| odf.migrated_version || odf }
  end

  def normalized_representation

    if original_datafiles.any? { |odf| odf.normalized_version }
      original_datafiles.map { |odf| odf.normalized_version || odf }
    else
      []
    end

  end

  def represented_datafiles
    (original_representation + current_representation + normalized_representation).uniq
  end

end
