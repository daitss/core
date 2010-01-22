require 'submission'
require 'spec'
require 'rack/test'
require 'digest/md5'
require 'stringio'
require 'sinatra'
require 'base64'

set :environment, :test

describe "Submission Service" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["DAITSS_WORKSPACE"] = "/tmp/d2ws"

    header "X_PACKAGE_NAME", "ateam"
    header "CONTENT_MD5", "901890a8e9c8cf6d5a1a542b229febff"
    header "X_ARCHIVE_TYPE", "zip"
  end

  after(:each) do
    FileUtils.rm_rf "/tmp/d2ws"
  end

  it "returns a 401 on any unauthorized requests" do
    get '/'
    last_response.status.should == 401

    delete '/'
    last_response.status.should == 401

    head '/'
    last_response.status.should == 401

    post '/'
    last_response.status.should == 401
  end


  it "returns 405 on GET" do
    get '/', {}, {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 405
  end

  it "returns 405 on DELETE" do
    delete '/', {}, {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 405
  end

  it "returns 405 on HEAD" do
    head '/', {}, {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 405
  end

  it "returns 400 on POST if request is missing X-Package-Name header" do
    header "X_PACKAGE_NAME", nil

    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "Missing header: X_PACKAGE_NAME" 
  end

  it "returns 400 on POST if request is missing Content-MD5 header" do
    header "CONTENT_MD5", nil

    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "Missing header: CONTENT_MD5" 
  end

  it "returns 400 on POST if request is missing X_ARCHIVE_TYPE header" do
    header "X_ARCHIVE_TYPE", nil

    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "Missing header: X_ARCHIVE_TYPE" 
  end


  it "returns 400 on POST if X_ARCHIVE_TYPE is a value different from 'tar' or 'zip'" do
    header "X_ARCHIVE_TYPE", "foo"

    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "X_ARCHIVE_TYPE header must be either 'tar' or 'zip'" 
  end

  it "returns 400 on POST if there is no body" do
    post "/", {}, {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "Missing body" 
  end

  it "returns 412 on POST if md5 checksum of body does not match md5 query parameter" do
    header "CONTENT_MD5", "cccccccccccccccccccccccccccccccc"

    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')} 

    last_response.status.should == 412
    last_response.body.should =~ /does not match/
  end

  it "should return 500 if there is an unexpected exception" do
    Digest::MD5.stub!(:new).and_raise(StandardError)
    
    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}
    last_response.status.should == 500

  end

  it "should return 400 if submitted package is not a zip file when request header says it should be" do
    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "Error extracting files in request body, is it malformed?" 
  end

  it "should return 400 if submitted package is not a tar file when request header says it should be" do
    header "X_ARCHIVE_TYPE", "tar"

    post "/", "FOO", {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    last_response.status.should == 400
    last_response.body.should == "Error extracting files in request body, is it malformed?" 
  end

  it "should return 200 on valid post request with a zip file" do
    sip_string = StringIO.new
    sip_md5 = Digest::MD5.new

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read 
    end

    # read into md5 object
    sip_string.rewind
    sip_md5 << sip_string.read

    # send the correct md5 header
    header "CONTENT_MD5", sip_md5.hexdigest
    
    # send request with real zip file
    post "/", sip_string, {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    ieid = last_response.headers["X_IEID"]

    # we should get back a 200 OK, with an encouraging word and the IEID in the header
    last_response.status.should == 200
    last_response.body.should == "<IEID>#{ieid}</IEID>"
    ieid.should_not be_nil
  end

  it "should return 200 on valid post request with a tar file" do
    sip_string = StringIO.new
    sip_md5 = Digest::MD5.new

    # read file into string io
    File.open "spec/test-sips/ateam.tar" do |sip_file|
      sip_string << sip_file.read 
    end

    # read into md5 object
    sip_string.rewind
    sip_md5 << sip_string.read

    # send the correct md5 header
    header "CONTENT_MD5", sip_md5.hexdigest
    header "X_ARCHIVE_TYPE", "tar"
    
    # send request with real zip file
    post "/", sip_string, {'HTTP_AUTHORIZATION' => encode_credentials('fda', 'subm1t')}

    ieid = last_response.headers["X_IEID"]

    # we should get back a 200 OK, with an encouraging word and the IEID in the header
    last_response.status.should == 200
    last_response.body.should == "<IEID>#{ieid}</IEID>"
    ieid.should_not be_nil
  end

  private

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
  
end
