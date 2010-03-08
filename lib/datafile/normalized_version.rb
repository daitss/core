require 'datafile'

class DataFile

  def normalized_version

    if metadata.has_key? 'normalized-version'
      DataFile.new @wip, metadata['normalized-version'] 
    end

  end

  def normalized_version= df
    metadata['normalized-version'] = df.id
  end

end
