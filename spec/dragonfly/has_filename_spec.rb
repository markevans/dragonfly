require 'spec_helper'

describe Dragonfly::HasFilename do
  
  before(:each) do
    @obj = Object.new
    class << @obj
      include Dragonfly::HasFilename
      attr_accessor :name
    end
  end

  describe "basename" do
    it "should define basename" do
      @obj.name = 'meat.balls'
      @obj.basename.should == 'meat'
    end
    it "should all but the last bit" do
      @obj.name = 'tooting.meat.balls'
      @obj.basename.should == 'tooting.meat'
    end
    it "should be nil if name not set" do
      @obj.basename.should be_nil
    end
    it "should be the whole name if it has no ext" do
      @obj.name = 'eggs'
      @obj.basename.should == 'eggs'
    end
  end
  
  describe "basename=" do
    it "should set the whole name if there isn't one" do
      @obj.basename = 'doog'
      @obj.name.should == 'doog'
    end
    it "should replace the whole name if there's no ext" do
      @obj.name = 'lungs'
      @obj.basename = 'doog'
      @obj.name.should == 'doog'
    end
    it "should replace all but the last bit" do
      @obj.name = 'bong.lungs.pig'
      @obj.basename = 'smeeg'
      @obj.name.should == 'smeeg.pig'
    end
  end
  
  describe "ext" do
    it "should define ext" do
      @obj.name = 'meat.balls'
      @obj.ext.should == 'balls'
    end
    it "should only use the last bit" do
      @obj.name = 'tooting.meat.balls'
      @obj.ext.should == 'balls'
    end
    it "should be nil if name not set" do
      @obj.ext.should be_nil
    end
    it "should be nil if name has no ext" do
      @obj.name = 'eggs'
      @obj.ext.should be_nil
    end
  end
  
  describe "ext=" do
    it "should use a default basename if there is no name" do
      @obj.ext = 'doog'
      @obj.name.should == 'file.doog'
    end
    it "should append the ext if name has none already" do
      @obj.name = 'lungs'
      @obj.ext = 'doog'
      @obj.name.should == 'lungs.doog'
    end
    it "should replace the ext if name has one already" do
      @obj.name = 'lungs.pig'
      @obj.ext = 'doog'
      @obj.name.should == 'lungs.doog'
    end
    it "should only replace the last bit" do
      @obj.name = 'long.lungs.pig'
      @obj.ext = 'doog'
      @obj.name.should == 'long.lungs.doog'
    end
  end
  
end
