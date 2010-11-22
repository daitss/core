require 'help/test_package'

require 'daitss/service/randystore'
require 'daitss/model'
include Daitss

describe RandyStore do

  let(:file) { File.join SIP_ARCHIVE_DIR, 'simple.tar' }
  let(:data) { File.read file }

  it 'should register for a new package' do
    package_id = EggHeadKey.new_egg_head_key
    rs = RandyStore.reserve package_id
  end

  it 'should put a new copy' do
    package_id = EggHeadKey.new_egg_head_key
    rs = RandyStore.reserve package_id
    rs.put data
  end

  it 'should put an update to an existing copy' do
    package_id = EggHeadKey.new_egg_head_key

    # an existing copy
    existing_rs = RandyStore.reserve package_id
    existing_rs.put data

    # a new copy
    new_rs = RandyStore.reserve package_id
    new_rs.url.should_not == existing_rs.url
    new_rs.put data
  end

  it 'should get' do
    package_id = EggHeadKey.new_egg_head_key
    rs = RandyStore.reserve package_id
    rs.put data
    rs.get.should == data
  end

  it 'should delete' do
    package_id = EggHeadKey.new_egg_head_key
    rs = RandyStore.reserve package_id
    rs.put data
    rs.delete
  end

  it 'should head' do
    pending 'seems to not be implemented'
    package_id = EggHeadKey.new_egg_head_key
    rs = RandyStore.reserve package_id
    rs.head
  end

end
