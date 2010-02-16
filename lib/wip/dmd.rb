require 'template'
require 'wip'

class Wip

  def has_dmd?

    ['dmd-issue', 'dmd-volume', 'dmd-title'].any? do |dmd_key|
      metadata.keys.include? dmd_key
    end

  end
  
  def dmd
    template_by_name('aip/dmd').result binding
  end

end
