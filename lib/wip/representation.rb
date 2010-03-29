require 'wip'

class Wip

  def load_representation key

    if metadata.has_key? key
      metadata[key].split.map { |id| DataFile.new self, id }
    else
      []
    end

  end

  def dump_representation key, dfs
    raise "#{key} contains a non-datafile" if dfs.any? { |df| df.class != DataFile }
    metadata[key] = dfs.map { |df| df.id }.join "\n"
  end

  class << self

    def attr_rep attr_symbol, key
      define_method(attr_symbol) { load_representation key }
      define_method("#{attr_symbol}=".to_sym) { |dfs| dump_representation key, dfs }
    end

  end

  attr_rep :original_rep, 'original-representation'
  attr_rep :current_rep, 'current-representation'
  attr_rep :normalized_rep, 'normalized-representation'

  def represented_file_partitions
    super_representation = ( self.original_rep + self.current_rep + self.normalized_rep ).uniq
    datafiles.partition { |df| super_representation.include?(df) }
  end

  def represented_files
    r, u = represented_file_partitions
    r
  end

  def unrepresented_files
    r, u = represented_file_partitions
    u
  end

end
