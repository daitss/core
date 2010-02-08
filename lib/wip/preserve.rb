require 'wip'
require 'wip/step'
require 'wip/representation'
require 'datafile/describe'
require 'datafile/actionplan'
require 'datafile/transform'
require 'datafile/normalized_version'

class Wip

  def preserve!

    datafiles.each do |df| 
      step("describe-#{df.id}") { df.describe! }
    end

    step 'set-original-representation' do
      self.original_rep = datafiles if original_rep.empty?
    end

    step 'set-current-representation'  do
      self.current_rep = original_rep if current_rep.empty?
    end

    new_current_rep = current_rep.map do |df| 

      step("migrate-#{df.id}") do
        transformation_url = df.migration

        if transformation_url
          products = df.transform transformation_url
          data, extension = products.first # XXX only 1-1 is supported now

          begin
            new_df = new_datafile
            new_df.open('w') { |io| io.write data }
            new_df['extension'] = extension
            new_df['aip-path'] = "#{df.id}-migration#{extension}"
            new_df.describe! :derivation_source => df.uri, :derivation_method => :migrate
            new_df
          rescue
            nuke_datafile new_df
            raise
          end

        else
          df
        end

      end

    end

    new_normalized_rep = original_rep.map do |df| 

      step("normalize-#{df.id}") do
        transformation_url = df.normalization

        if transformation_url
          products = df.transform transformation_url
          data, extension = products.first # XXX only 1-1 is supported now

          begin
            norm_df = df.normalized_version || new_datafile 
            norm_df.open('w') { |io| io.write data }
            norm_df['extension'] = extension
            norm_df['aip-path'] = "#{df.id}-normalization#{extension}"

            step "describe-#{norm_df.id}" do
              norm_df.describe! :derivation_source => df.uri, :derivation_method => :normalize
            end

            norm_df
          rescue
            remove_datafile norm_df
            raise
          end

        else
          df
        end

      end

    end

    step 'update-current-representation' do
      self.current_rep = new_current_rep unless new_current_rep == current_rep
    end

    step 'update-normalized-representation' do
      self.normalized_rep = new_normalized_rep unless new_normalized_rep == normalized_rep
    end

    unrepresented_files.each do |df| 
      step("obsolete-#{df.id}") { df.obsolete! }
    end

  end

end
