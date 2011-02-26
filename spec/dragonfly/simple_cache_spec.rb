require 'spec_helper'

describe Dragonfly::SimpleCache do
  
  before(:each) do
    @cache = Dragonfly::SimpleCache.new(2)
  end
  
  it "should act as a normal hash" do
    @cache[:egg] = 'four'
    @cache[:egg].should == 'four'
  end
  
  it "should allow filling up to the limit" do
    @cache[:a] = 1
    @cache[:b] = 2
    @cache.should == {:a => 1, :b => 2}
  end
  
  it "should get rid of the first added when full" do
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3
    @cache.should == {:b => 2, :c => 3}
  end
  
end
