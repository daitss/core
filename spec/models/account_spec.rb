describe Account do

  it "should be invalid without a default project" do
    a = Account.create :id => "foo"
    a.projects.first(:id => DEFAULT_PROJECT_ID).destroy
    a.reload
    a.should_not be_valid
  end

  it "should be valid with a default project" do
    a = Account.new :id => "foo"
    a.save.should be_true
    a.should be_valid
  end

end
