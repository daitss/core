require 'spec_helper'
require 'wip'
require 'representation'

describe "representation handling" do

  before(:all) do
    @wip = submit_sip 'mimi'
  end

  it "should inject through text" do
    rep = @wip.datafiles
    @wip.dump_representation 'original', rep 
    other = @wip.load_representation 'original'
    rep.should == other
  end

  it "should have accessor sugar" do
    @wip.original_rep.should == @wip.load_representation('original-representation')
    @wip.current_rep.should == @wip.load_representation('current-representation')
    @wip.normalized_rep.should == @wip.load_representation('normalized-representation')
  end

  it "should have mutator sugar" do
    pending
  end

end

