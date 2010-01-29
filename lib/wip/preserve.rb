require 'wip'
require 'wip/step'
require 'service/describe'
require 'service/actionplan'
require 'service/transform'

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

    step 'set-normalized-representation' do
      self.normalized_rep = original_rep
    end

    new_current_rep = current_rep.map do |df| 
      transformation_url = df.migration

      if transformation_url
        new_df = step("migrate-#{df.id}") { df.transform transformation_url } 
        step("describe-#{new_df.id}") { new_df.describe! :derivation => df } 
        new_df
      else
        df
      end

    end

    new_normalized_rep = normalized_rep.map do |df| 
      transformation_url = df.normalization

      if transformation_url
        products = step("normalize-#{df.id}") { df.transform transformation_url }
        data, extension = products.first # XXX only 1-1 is supported now

        new_df = new_datafile
        new_df.open('w') { |io| io.write data }
        new_df['extension'] = extension
        new_df['aip-path'] = "#{df.id}-normalization#{extension}"

        step("describe-#{new_df.id}") { new_df.describe! :derivation => df } 

        new_df
      else
        df
      end

    end

    step 'update-current-representation' do
      self.current_rep = new_current_rep unless new_current_rep == current_rep
    end

    step 'update-normalized-representation' do
      self.normalized_rep = new_normalized_rep unless new_normalized_rep == normalized_rep
    end

    # clean out undescribed files
    represented_files, unrepresented_files = represented_file_partitions
    unrepresented_files.each { |df| step("obsolete-#{df.id}") { df.obsolete! } }
  end

end
