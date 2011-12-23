require 'spec_helper'

describe Dragonfly::UrlAttributes do
  
  before(:each) do
    @hash = Dragonfly::UrlAttributes.new
  end

  describe "name" do
    it "should default to nil" do
      @hash.name.should be_nil
    end
    it "should return the name if set" do
      @hash[:name] = 'long.pigs'
      @hash.name.should == 'long.pigs'
    end
    it "should allow setting via an accessor" do
      @hash.name = 'john.doe'
      @hash[:name].should == 'john.doe'
    end
  end
  
  describe "sanity check for use of HasFilename" do
    it "should provide ext and basename" do
      @hash.name = 'dog.leg'
      @hash.basename.should == 'dog'
      @hash.ext.should == 'leg'
    end
  end

  describe "slice" do
    it "should return a subset of the params" do
      hash = Dragonfly::UrlAttributes[:a => 1, :b => 2, :c => 3]
      hash.slice(:a, :b).should == {:a => 1, :b => 2}
    end
    it "should use the method instead of the param for basename" do
      Dragonfly::UrlAttributes[:name => 'hello.ted'].slice(:basename).should == {:basename => 'hello'}
    end
    it "should use the method instead of the param for ext" do
      Dragonfly::UrlAttributes[:name => 'hello.ted'].slice(:ext).should == {:ext => 'ted'}
    end
    it "should treat strings like symbols" do
      Dragonfly::UrlAttributes[:yog => 'gurt', :john => 'doe'].slice('yog').should == {:yog => 'gurt'}
    end
  end

end
