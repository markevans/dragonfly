require 'spec_helper'

describe Dragonfly::HashWithName do
  
  before(:each) do
    @hash = Dragonfly::HashWithName.new
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
  
  describe "ext" do
    it "should default to nil" do
      @hash.ext.should be_nil
    end
    it "should use the :ext key if set" do
      @hash[:ext] = 'hello'
      @hash.ext.should == 'hello'
    end
    it "should use the :name key if set" do
      @hash[:name] = 'hello.there.mate'
      @hash.ext.should == 'mate'
    end
    it "should allow setting" do
      @hash.ext = 'down'
      @hash.ext.should == 'down'
    end
    it "should update the name too when setting" do
      @hash[:name] = 'hello.there.mate'
      @hash.ext = 'pog'
      @hash.should == {:name => 'hello.there.pog', :ext => 'pog'}
    end
  end

  describe "basename" do
    it "should default to nil" do
      @hash.basename.should be_nil
    end
    it "should use the :basename key if set" do
      @hash[:basename] = 'hello.there'
      @hash.basename.should == 'hello.there'
    end
    it "should use the :name key if set" do
      @hash[:name] = 'hello.there.mate'
      @hash.basename.should == 'hello.there'
    end
    it "should allow setting" do
      @hash.basename = 'chin'
      @hash.basename.should == 'chin'
    end
    it "should update the name too when setting" do
      @hash[:name] = 'hello.there.mate'
      @hash.basename = 'duggs'
      @hash.should == {:name => 'duggs.mate', :basename => 'duggs'}
    end
  end

end
