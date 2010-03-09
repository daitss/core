require 'spec_helper'
require 'wip'
require 'wip/representation'

describe "representation handling" do

  before(:all) do
    @wip = submit 'mimi'
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
    r = @wip.datafiles

    @wip.original_rep = r[0..0]
    @wip.original_rep.should == r[0..0]
    @wip.original_rep.should_not == r

    @wip.current_rep = r[0..0]
    @wip.current_rep.should == r[0..0]
    @wip.current_rep.should_not == r

    @wip.normalized_rep = r[0..0]
    @wip.normalized_rep.should == r[0..0]
    @wip.normalized_rep.should_not == r
  end

end

