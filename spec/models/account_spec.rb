describe Account do

  it "should have be invalid without a default project" do
    a = Account.new :id => "foo"
    a.save.should be_false
    a.should_not be_valid
  end

  it "should have be valid with a default project" do
    a = Account.new :id => "foo"
    a.projects << Project.new_default_project
    a.save.should be_true
    a.should be_valid
  end

end
