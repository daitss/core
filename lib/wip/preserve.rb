require 'wip'
require 'wip/step'
require 'datafile/describe'
require 'datafile/transform'

class Wip

  def preserve!

    original_datafiles.each do |df|
      step("describe-#{df.id}") { df.describe! }
      step("migrate-#{df.id}") { df.migrate! }
      step("normalize-#{df.id}") { df.normalize! }
    end

    (migrated_datafiles + normalized_datafiles).each do |df|
      step("describe-#{df.id}") { df.describe! }
    end

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
