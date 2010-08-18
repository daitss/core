require 'spec_helper'

require 'daitss/proc/sip_archive'

describe SipArchive do

  it 'should raise an error if the archive type is unknown' do
    name = 'haskell-nums-pdf.jar'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    lambda { SipArchive.new path }.should raise_error('unknown archive extension: .jar')
    FileUtils.rm_r dir
  end

  it 'should raise an error if the extraction does not result in a directory' do
    name = 'not-a-package.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    lambda { SipArchive.new path }.should raise_error("#{name} is not a package")
    FileUtils.rm_r dir
  end

end
