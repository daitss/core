require 'service/store'

describe Store do

  let(:file) { sip_fixture_path 'simple.tar' }
  let(:data) { File.read file }

  it 'should register for a new package' do
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
  end

  it 'should put a new copy' do
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
    rs.put data
  end

  it 'should put a new copy from a file' do
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
    rs.put_file file
  end

  it 'should put an update to an existing copy' do
    package_id = EggHeadKey.new_egg_head_key

    # an existing copy
    existing_rs = Store.reserve package_id
    existing_rs.put data

    # a new copy
    new_rs = Store.reserve package_id
    new_rs.url.should_not == existing_rs.url
    new_rs.put data
  end

  it 'should get' do
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
    rs.put data
    rs.get.should == data
  end

  it 'should download' do
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
    rs.put data
    f = File.join ENV['TMPDIR'], "download-#{rand(10000).to_s(36)}"
    File.exist?(f).should_not be_true
    rs.download f
    Digest::SHA1.file(f).should == Digest::SHA1.file(file)
    FileUtils.rm f
  end

  it 'should delete' do
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
    rs.put data
    rs.delete
  end

  it 'should head' do
    pending "fails, storage error?"
    package_id = EggHeadKey.new_egg_head_key
    rs = Store.reserve package_id
    rs.head
  end

end
