require 'wip'
require 'wip/step'
require 'wip/xmlresolve'
require 'datafile/describe'
require 'datafile/obsolete'
require 'datafile/transform'

class Wip

  def preserve!

    # describe and preserve original_files
    original_datafiles.each do |df|
      step("describe-#{df.id}") { df.describe! }
      step("migrate-#{df.id}") { df.migrate! }
      step("normalize-#{df.id}") { df.normalize! }
    end

    # describe transformed files
    tfs = (migrated_datafiles + normalized_datafiles).reject { |df| df.obsolete? }
    tfs.each { |df| step("describe-#{df.id}") { df.describe! } }

    # xmlresolve this wip
    # XXX this is disabled until xmlresolution gives valid elements
    #step('xml-resolution') { xmlresolve! }
  end

  def original_representation
    original_datafiles
  end

  def current_representation
    original_datafiles.map { |odf| odf.migrated_version || odf }
  end

  def normalized_representation
    original_datafiles.map { |odf| odf.normalized_version || odf }
  end

  def represented_datafiles
    (original_representation + current_representation + normalized_representation).uniq
  end

end
