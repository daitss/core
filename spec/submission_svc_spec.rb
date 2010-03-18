require 'submission'
require 'spec'
require 'rack/test'
require 'digest/md5'
require 'stringio'
require 'sinatra'
require 'base64'
require 'helper'


describe Submission::App do

  include Rack::Test::Methods

  def app
    Submission::App
  end

  def authenticated_post uri, username, password, middle_param = {}
    post uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

  def authenticated_get uri, username, password, middle_param = {}
    get uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

  def authenticated_delete uri, username, password, middle_param = {}
    delete uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

  def authenticated_head uri, username, password, middle_param = {}
    head uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["DAITSS_WORKSPACE"] = "/tmp/d2ws"

    header "X_PACKAGE_NAME", "ateam"
    header "CONTENT_MD5", "901890a8e9c8cf6d5a1a542b229febff"
    header "X_ARCHIVE_TYPE", "zip"

    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")
    DataMapper.auto_migrate!

    a = add_account "ACT", "ACT"
    add_operator a
    add_contact a
  end

  after(:each) do
    FileUtils.rm_rf "/tmp/d2ws"
  end

  it "returns 405 on GET" do
    authenticated_get "/", "operator", "operator"

    last_response.status.should == 405
  end

  it "returns 405 on DELETE" do
    authenticated_delete "/", "operator", "operator"

    last_response.status.should == 405
  end

  it "returns 405 on HEAD" do
    authenticated_head "/", "operator", "operator"

    last_response.status.should == 405
  end

  it "returns 400 on POST if request is missing X-Package-Name header" do
    header "X_PACKAGE_NAME", nil

    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Missing header: X_PACKAGE_NAME" 
  end

  it "returns 400 on POST if request is missing Content-MD5 header" do
    header "CONTENT_MD5", nil

    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Missing header: CONTENT_MD5" 
  end

  it "returns 400 on POST if request is missing X_ARCHIVE_TYPE header" do
    header "X_ARCHIVE_TYPE", nil

    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Missing header: X_ARCHIVE_TYPE" 
  end


  it "returns 400 on POST if X_ARCHIVE_TYPE is a value different from 'tar' or 'zip'" do
    header "X_ARCHIVE_TYPE", "foo"

    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 400
    last_response.body.should == "X_ARCHIVE_TYPE header must be either 'tar' or 'zip'" 
  end

  it "returns 400 on POST if there is no body" do
    authenticated_post "/", "operator", "operator"

    last_response.status.should == 400
    last_response.body.should == "Missing body" 
  end

  it "returns 412 on POST if md5 checksum of body does not match md5 query parameter" do
    header "CONTENT_MD5", "cccccccccccccccccccccccccccccccc"

    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 412
    last_response.body.should =~ /does not match/
  end

  it "should return 500 if there is an unexpected exception" do
    Digest::MD5.stub!(:new).and_raise(StandardError)
    
    authenticated_post "/", "operator", "operator", "FOO"
    last_response.status.should == 500

  end

  it "should return 400 if submitted package is not a zip file when request header says it should be" do
    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 400
    last_response.body.should == "Error extracting files in request body, is it malformed?" 
  end

  it "should return 400 if submitted package is not a tar file when request header says it should be" do
    header "X_ARCHIVE_TYPE", "tar"

    authenticated_post "/", "operator", "operator", "FOO"

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
    authenticated_post "/", "operator", "operator", sip_string

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
    authenticated_post "/", "operator", "operator", sip_string

    ieid = last_response.headers["X_IEID"]

    # we should get back a 200 OK, with an encouraging word and the IEID in the header
    last_response.status.should == 200
    last_response.body.should == "<IEID>#{ieid}</IEID>"
    ieid.should_not be_nil
  end

  it "should return 401 if a set of credentials are not provided" do
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
    
    # send request with real zip file, but with no credentials
    post "/", sip_string

    last_response.status.should == 401
  end

  it "should return 403 if agent is not authorized to submit" do
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
    
    # send request with real zip file, but with credentials for contact without submit permission
    authenticated_post "/", "foobar", "foobar", sip_string

    last_response.status.should == 403
  end

  it "should return 403 if agent is not authenticated" do
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
    
    # send request with real zip file, but with wrong credentials
    authenticated_post "/", "operator", "foobar", sip_string

    last_response.status.should == 403
  end

  it "should return 403 if the submitting user's account does not match the account in the package descriptor" do
    sip_string = StringIO.new
    sip_md5 = Digest::MD5.new

    # read file into string io
    File.open "spec/test-sips/ateam-wrong-account.zip" do |sip_file|
      sip_string << sip_file.read 
    end

    # read into md5 object
    sip_string.rewind
    sip_md5 << sip_string.read

    # send the correct md5 header
    header "CONTENT_MD5", sip_md5.hexdigest
    
    # send request with real zip file, but with an account of "FOO" specified in the descriptor
    authenticated_post "/", "contact", "contact", sip_string

    last_response.status.should == 403
  end

  it "should return 200 if the submitting user's account does not match the account in the package descriptor if the submitter is an operator" do
    sip_string = StringIO.new
    sip_md5 = Digest::MD5.new

    # read file into string io
    File.open "spec/test-sips/ateam-wrong-account.zip" do |sip_file|
      sip_string << sip_file.read 
    end

    # read into md5 object
    sip_string.rewind
    sip_md5 << sip_string.read

    # send the correct md5 header
    header "CONTENT_MD5", sip_md5.hexdigest
    
    # send request with real zip file, but with an account of "FOO" specified in the descriptor
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 200
  end

  private

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
