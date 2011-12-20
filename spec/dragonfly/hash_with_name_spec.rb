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

  describe "slice" do
    it "should return a subset of the params" do
      hash = Dragonfly::HashWithName[:a => 1, :b => 2, :c => 3]
      hash.slice(:a, :b).should == {:a => 1, :b => 2}
    end
    it "should use the method instead of the param for basename" do
      Dragonfly::HashWithName[:name => 'hello.ted'].slice(:basename).should == {:basename => 'hello'}
    end
    it "should use the method instead of the param for ext" do
      Dragonfly::HashWithName[:name => 'hello.ted'].slice(:ext).should == {:ext => 'ted'}
    end
  end

end
