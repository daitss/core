require 'spec_helper'

require 'daitss/proc/sip_archive'

describe SipArchive do

  it "should be an error if the package name is too long"

  it "should be an error if the package name is contains invalid characters" do
    name = %q{.bad '" names 1 2 3 4 5 6 7 8 9 a b c d e f.zip}
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    lambda { SipArchive.new path }.should raise_error("invalid characters in sip name")
  end

  it "should raise error and create sip record if archive cannot be extracted" do
    name = 'not-an-archive.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    lambda { SipArchive.new path }.should raise_error(/^error extracting #{name}/)
    FileUtils.rm_r dir
  end

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

  it "should create sip from zip file" do
    name = 'haskell-nums-pdf.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    lambda { SipArchive.new path }.should_not raise_error
    FileUtils.rm_r dir
  end

  it "should create sip from tar file" do
    name = 'haskell-nums-pdf.tar'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    lambda { SipArchive.new path }.should_not raise_error
    FileUtils.rm_r dir
  end

  it "should be invalid and contain an error if descriptor is not found" do
    name = 'missing-descriptor.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    sa = SipArchive.new path
    sa.should_not be_valid

    sa.errors.should include('missing descriptor')
  end

  it "should be invalid and contain an error is the descriptor is invalid" do
    name = 'invalid-descriptor.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    sa = SipArchive.new path
    sa.should_not be_valid

    sa.errors.should include("invalid descriptor")
    sa.errors.should include(%q{44: cvc-complex-type.2.3: Element 'structMap' cannot have character [children], because the type's content type is element-only.})
    sa.errors.should include(%q{44: cvc-complex-type.2.4.b: The content of element 'structMap' is not complete. One of '{"http://www.loc.gov/METS/":div}' is expected.})
  end

  it "should be invalid and contain an error is the account is invalid"
  it "should be invalid and contain an error is the project is invalid"

  it "should be invalid and contain an error for every content file with an invalid checksum" do
    name = 'bad-checksum.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('SHA-1 for Haskell98numbers.pdf - expected: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; computed d20d46494e5145f68b6e9938a9bbd80d36d28c69')
  end
  #@errors.push REJECT_CHECKSUM_MISMATCH unless wip.content_file_checksums_match?

  it "should be invalid and contain an error if there are no content files" do
    name = 'missing-content-files.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('missing content files')
  end

  it "should be invalid and contain errors if any files have invalid names" do
    name = 'bad-file-names.zip'
    dir = Dir.mktmpdir
    FileUtils.cp sip_archive_fixture(name), dir
    path = File.join dir, name

    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("invalid characters in file name: .bad ' file")
    sa.errors.should include("invalid characters in file name: .bad \" file")
  end

end
