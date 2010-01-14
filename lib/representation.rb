require 'wip'

class Wip

  def represented_partitions

    o = original_rep
    c = current_rep
    n = normalized_rep

    datafiles.partition do |df|
      o.include?(df) or c.include?(df) or n.include?(df)
    end

  end

  def original_rep
    load_rep 'original-representation'
  end

  def original_rep= dfs
    store_rep 'original-representation', dfs
  end

  def current_rep
    load_rep 'current-representation'
  end

  def current_rep= dfs
    store_rep 'current-representation', dfs
  end

  def normalized_rep
    load_rep 'normalized-representation'
  end

  def normalized_rep= dfs
    store_rep 'normalized-representation', dfs
  end

  private

  def load_rep key
    (metadata[key] or '').split.map { |id| DataFile.new self, id }
  end

  def store_rep key, dfs 
    metadata[key] = dfs.map { |df| df.id }.join "\n"
  end

end
