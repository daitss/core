require 'daitss/model/account'

describe Account do
  it "should automatically create a default project if one doesn't already exist" do
    a = Account.new :id => "foo"
    a.save

    a.default_project.should_not be_nil
    a.default_project.id.should == Daitss::Archive::DEFAULT_PROJECT_ID
  end
end

