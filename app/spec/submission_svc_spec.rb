require 'helper'

require 'submission'
require 'spec'
require 'rack/test'
require 'digest/md5'
require 'stringio'
require 'sinatra'
require 'base64'
require 'daitss/config'

include Daitss

describe "submission service" do

  include Rack::Test::Methods

  def app
    Sinatra::Application
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
    CONFIG.load_from_env

    DataMapper.setup(:default, CONFIG['database-url'])
    DataMapper.auto_migrate!

    header "X_PACKAGE_NAME", "ateam"

    a = add_account "ACT", "ACT"
    add_project a
    add_operator a
    add_contact a

    b = add_account "UF", "UF"
    add_project b
    add_contact b, [:submit], "bernie", "bernie"
    add_operator b, "uf_op", "uf_op"
  end

  after(:each) do
    FileUtils.rm_rf Dir.glob(File.join(CONFIG['workspace'], "*")) if CONFIG['workspace'].length > 0 and Dir.entries(CONFIG['workspace']) == 3
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

  it "returns 400 on POST if there is no body" do
    authenticated_post "/", "operator", "operator"

    last_response.status.should == 400
    last_response.body.should == "Missing body"
  end

  it "should return 500 if there is an unexpected exception" do
    OldIeid.stub!(:get_next).and_raise(StandardError)

    authenticated_post "/", "operator", "operator", "FOO"
    last_response.status.should == 500
  end

  it "should return 400 if submitted package is not a valid archive file" do
    authenticated_post "/", "operator", "operator", "FOO"

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_ARCHIVE_EXTRACTION_ERROR}/

    ieid = last_response.body.split(":")[0]
    SubmittedSip.first(:ieid => ieid).should_not be_nil
  end

  it "should return 200 on valid post request with a zip file" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read
    end

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

    # read file into string io
    File.open "spec/test-sips/ateam.tar" do |sip_file|
      sip_string << sip_file.read
    end

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

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but with no credentials
    post "/", sip_string

    last_response.status.should == 401
  end

  it "should return 403 if agent is not authorized to submit" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but with credentials for contact without submit permission
    authenticated_post "/", "foobar", "foobar", sip_string

    last_response.status.should == 403
  end

  it "should return 403 if agent is not authenticated" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but with wrong credentials
    authenticated_post "/", "operator", "foobar", sip_string

    last_response.status.should == 403
  end

  it "should return 400 if the submitting user's account does not match the account in the package descriptor" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file
    authenticated_post "/", "bernie", "bernie", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_SUBMITTER_DESCRIPTOR_ACCOUNT_MISMATCH}/
  end

  it "should return 200 if the submitting user's account does not match the account in the package descriptor if the submitter is an operator" do
    pending 'Wip#from_sip handles this, refactor logic!'
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but with an account of "FOO" specified in the descriptor
    authenticated_post "/", "uf_op", "uf_op", sip_string

    last_response.status.should == 200
  end

  it "should return 400 if the specified project does not exist" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-bad-project.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but with an project of "DNE" specified in the descriptor
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_INVALID_PROJECT}/
  end

  it "should return 400 if the specified account does not exist" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-bad-account.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but with an account of "DNE" specified in the descriptor
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_INVALID_ACCOUNT}/
  end

  it "should raise 400 if package is missing content files" do
    pending 'Wip#from_sip handles this, refactor logic!'
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-missing-contentfile.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file, but having no content files
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_MISSING_CONTENT_FILE}/
  end

  it "should raise 400 if there is a checksum mismatch between the sip descriptor and a datafile" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-checksum-mismatch.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file in which the descriptor has the wrong checksum
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_CHECKSUM_MISMATCH}/
  end

  it "should raise 400 if package is missing sip descriptor" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-nodesc.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file in which the descriptor has been deleted
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_DESCRIPTOR_NOT_FOUND}/
  end

  it "should raise 400 if sip descriptor is not well formed" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-broken-descriptor.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file in which the descriptor is invalid
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_INVALID_DESCRIPTOR}/
  end

  it "should raise 400 if sip descriptor is does not validate" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-invalid-descriptor.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file in which the descriptor is invalid
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_INVALID_DESCRIPTOR}/
  end

  it "should raise 400 and report all errors if sip contains multiple errors" do
    sip_string = StringIO.new

    # read file into string io
    File.open "spec/test-sips/ateam-multiple-problems.zip" do |sip_file|
      sip_string << sip_file.read
    end

    # send request with real zip file in which the descriptor is invalid
    authenticated_post "/", "operator", "operator", sip_string

    last_response.status.should == 400
    last_response.body.should =~ /#{REJECT_INVALID_DATAFILE_NAME}/
    last_response.body.should =~ /#{REJECT_CHECKSUM_MISMATCH}/
    last_response.body.should =~ /#{REJECT_INVALID_PROJECT}/
  end

  private

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
