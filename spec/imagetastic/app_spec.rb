require File.dirname(__FILE__) + '/../spec_helper'
require 'rack/mock'

describe Imagetastic::App do

  describe ".instance" do
    
    it "should create a new instance if it didn't already exist" do
      app = Imagetastic::App.instance(:images)
      app.should be_a(Imagetastic::App)
    end
    
    it "should return an existing instance if called by name" do
      app = Imagetastic::App.instance(:images)
      Imagetastic::App.instance(:images).should == app
    end
    
    it "should also work using square brackets" do
      Imagetastic::App[:images].should == Imagetastic::App.instance(:images)
    end
    
  end
  
  describe ".new" do
    it "should not be callable" do
      lambda{
        Imagetastic::App.new
      }.should raise_error(NoMethodError)
    end
  end

end