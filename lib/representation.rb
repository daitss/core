module Representation

  def original_rep
    get_representation 'original-representation'
  end

  def original_rep= dfs
    set_representation 'original-representation', dfs
  end

  private

  def get_representation key
    metadata[key].split.map { |id| Datafile.new self, id }
  end

  def set_representation key, dfs 
    metadata[key] = dfs.map { |df| df.id }.join "\n"
  end

  # Returns all files that are of the original representation
  def original_representation
    datafiles.reject { |f| f.migration_src or f.normalization_src }
  end

  # Returns all files that are of the current representation
  def current_representation
    non_norms = files.reject { |f| f.normalization_src }
    non_norms.map { |f| f.migration_src or f }.uniq 
  end

  # Returns all the files that are of the normalized representation
  def normalized_representation
    non_migrs = files.reject { |f| f.normalization_src }
    non_migrs.map { |f| f.normalization_src or f }.uniq
  end

end
