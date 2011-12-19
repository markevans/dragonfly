require 'spec_helper'

describe Dragonfly::HashWithName do
  
  before(:each) do
    @hash = Dragonfly::HashWithName.new
  end

  describe "name" do
    it "should default to nil" do
      @hash[:name].should be_nil
    end
    it "should allow setting via normal hash access" do
      @hash[:name] = 'long.pigs'
      @hash[:name].should == 'long.pigs'
    end
    it "should allow reading via an accessor" do
      @hash[:name] = 'long.pigs'
      @hash.name.should == 'long.pigs'
    end
    it "should allow setting via an accessor" do
      @hash.name = 'john.doe'
      @hash[:name].should == 'john.doe'
    end
    it "should allow setting to nil" do
      @hash[:name] = 'long.pigs'
      @hash[:name] = nil
      @hash[:name].should be_nil
    end
  end
  
  describe "ext" do
    it "should use the correct extension from name" do
      @hash[:name] = 'hello.there.mate'
      @hash[:ext].should == 'mate'
    end
    it "should be nil if name has none" do
      @hash[:name] = 'hello'
      @hash[:ext].should be_nil
    end
    it "should be nil if name is nil" do
      @hash[:name] = nil
      @hash[:ext].should be_nil
    end
    it "should allow setting" do
      @hash[:ext] = 'duggs'
      @hash[:ext].should == 'duggs'
    end
    it "should update the name too" do
      @hash[:name] = 'hello.there.mate'
      @hash[:ext] = 'duggs'
      @hash[:name].should == 'hello.there.duggs'
    end
  end

  describe "basename" do
    it "should use the correct basename from name" do
      @hash[:name] = 'hello.there.mate'
      @hash[:basename].should == 'hello.there'
    end
    it "should be nil if name is nil" do
      @hash[:name] = nil
      @hash[:basename].should be_nil
    end
    it "should allow setting" do
      @hash[:basename] = 'duggs'
      @hash[:basename].should == 'duggs'
    end
    it "should update the name too" do
      @hash[:name] = 'hello.there.mate'
      @hash[:basename] = 'duggs'
      @hash[:name].should == 'duggs.mate'
    end
  end

  describe "initializing with []" do
    it "should still work" do
      hash = Dragonfly::HashWithName[:name => 'mark.duggan']
      hash[:name].should == 'mark.duggan'
      hash[:ext].should == 'duggan'
    end
  end

end
