require 'wip'
require 'wip/step'
require 'wip/representation'
require 'datafile/describe'
require 'datafile/actionplan'
require 'datafile/transform'
require 'datafile/normalized_version'

class Wip

  def preserve!

    original_datafiles.each do |df|
      step("describe-#{df.id}") { df.describe! }
      step("migrate-#{df.id}") { df.migrate! }
      step("normalize-#{df.id}") { df.normalize! }
    end

    migrated_datafiles.each do |df|
      step("describe-#{df.id}") { df.describe! }
    end

    normalized_datafiles.each do |df|
      step("describe-#{df.id}") { df.describe! }
    end

    original_datafiles.each do |df|
      transformation_url = df.normalization

      if transformation_url
        data, extension = df.transform transformation_url

        new_id = if df.normalized_version.nil?
                   "#{odf.id}-norm-0"
                 else

                   if df.normalized_version.id =~ /#{odf.id}-norm-(\d+)/
                     "#{odf.id}-norm-#{$1.to_i + 1}"
                   else
                     raise "normalized id is ill formed"
                   end

                 end

        begin
          new_df = new_normalized_datafile new_id
          new_df.open('w') { |io| io.write data }
          new_df['extension'] = extension
          new_df['aip-path'] = "#{df.id}-normalization#{extension}"
          new_df.describe!(:derivation_source => df.uri,
                           :derivation_method => :normalize,
                           :derivation_agent => transformation_url)

        rescue
          remove_normalized_datafile new_df
          raise
        end

      end

    end

  end

end
