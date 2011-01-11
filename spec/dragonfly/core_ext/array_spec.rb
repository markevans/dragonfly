require 'spec_helper'

describe Array do
  
  describe "to_dragonfly_unique_s" do
    it "should concatenate the to_s's of each of the elements" do
      [:a, true, 2, 5.2, "hello"].to_dragonfly_unique_s.should == 'atrue25.2hello'
    end
    
    it "should nest arrays" do
      [:a, [:b, :c], :d].to_dragonfly_unique_s.should == 'abcd'
    end
    
    it "should be empty if empty" do
      [].to_dragonfly_unique_s.should == ''
    end
  end
  
end
