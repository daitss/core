require 'spec_helper'
require 'daitss/proc/wip'

describe Daitss::Wip do

  let :package do
    wip = submit 'haskell-nums-pdf'
    wip.ingest
    FileUtils.rm_r wip.path
    wip.package
  end

  it 'should have an aip' do
    package.aip.should_not be_nil
  end

  it 'should have a copy' do
    package.aip.copy.should_not be_nil
  end

  it 'should have an intentity' do
    package.intentity.should_not be_nil
  end

end
