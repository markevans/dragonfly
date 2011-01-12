require 'spec_helper'

describe Hash do
  
  describe "to_dragonfly_unique_s" do
    it "should concatenate the to_s's of each of the elements, sorted alphabetically" do
      {'z' => nil, :a => 4, false => 'ice', 5 => 6.2}.to_dragonfly_unique_s.should == '56.2a4falseicez'
    end

    it "should nest correctly" do
      {:m => 1, :a => {:c => 2, :b => 3}, :z => 4}.to_dragonfly_unique_s.should == 'ab3c2m1z4'
    end
    
    it "should be empty if empty" do
      {}.to_dragonfly_unique_s.should == ''
    end
  end
  
end
