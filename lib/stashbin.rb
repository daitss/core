require 'daitss/config'

class StashBin
  include Daitss
  include DataMapper::Resource

  property :name, String, :key => true

  def wips
    pattern = File.join path, '*'
    Dir[pattern].map { |p| Wip.new p }
  end

  def url_name
    URI.escape name
  end

  def sha1
    Digest::SHA1.hexdigest name
  end

  def path
    File.join CONFIG['stashspace'], sha1
  end

  def unstash wip_id
    src = File.join path, wip_id
    dst = File.join CONFIG['workspace'], wip_id
    FileUtils.mv src, dst
  end

end
