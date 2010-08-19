require 'spec_helper'
require 'daitss/proc/sip_archive'

describe SipArchive do

  it "should be an error if the package name is too long" do
    path = new_sip_archive 'very-long-name-0123456789abcdefABCDEF.zip'
    lambda { SipArchive.new path }.should raise_error("package name contains too many characters (37) max is 32")
  end

  it "should be an error if the package name is contains invalid characters" do
    path = new_sip_archive %q{.bad '" names 1 2 3 4 5 6 7 8 9 a b c d e f.zip}
    lambda { SipArchive.new path }.should raise_error("invalid characters in sip name")
  end

  it "should raise error and create sip record if archive cannot be extracted" do
    path = new_sip_archive 'not-an-archive.zip'
    lambda { SipArchive.new path }.should raise_error(/^error extracting not-an-archive\.zip/)
  end

  it 'should raise an error if the archive type is unknown' do
    path = new_sip_archive 'haskell-nums-pdf.jar'
    lambda { SipArchive.new path }.should raise_error('unknown archive extension: .jar')
  end

  it 'should raise an error if the extraction does not result in a directory' do
    path = new_sip_archive 'not-a-package.zip'
    lambda { SipArchive.new path }.should raise_error("not-a-package.zip is not a package")
  end

  it "should create sip from zip file" do
    path = new_sip_archive 'haskell-nums-pdf.zip'
    lambda { SipArchive.new path }.should_not raise_error
  end

  it "should create sip from tar file" do
    path = new_sip_archive 'haskell-nums-pdf.tar'
    lambda { SipArchive.new path }.should_not raise_error
  end

  it "should be invalid and contain an error if descriptor is not found" do
    path = new_sip_archive 'missing-descriptor.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('missing descriptor')
  end

  it "should be invalid and contain an error is the descriptor is invalid" do
    path = new_sip_archive 'invalid-descriptor.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("invalid descriptor")
    sa.errors.should include(%q{44: cvc-complex-type.2.3: Element 'structMap' cannot have character [children], because the type's content type is element-only.})
    sa.errors.should include(%q{44: cvc-complex-type.2.4.b: The content of element 'structMap' is not complete. One of '{"http://www.loc.gov/METS/":div}' is expected.})
  end

  it "should be invalid and contain an error is the account is invalid"
  it "should be invalid and contain an error is the project is invalid"

  it "should be invalid and contain an error for every content file with an invalid checksum" do
    path = new_sip_archive 'bad-checksum.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('SHA-1 for Haskell98numbers.pdf - expected: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; computed d20d46494e5145f68b6e9938a9bbd80d36d28c69')
  end

  it "should be invalid and contain an error if there are no content files" do
    path = new_sip_archive 'missing-content-files.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('missing content files')
  end

  it "should be invalid and contain errors if any files have invalid names" do
    path = new_sip_archive 'bad-file-names.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("invalid characters in file name: .bad ' file")
    sa.errors.should include("invalid characters in file name: .bad \" file")
  end

end
