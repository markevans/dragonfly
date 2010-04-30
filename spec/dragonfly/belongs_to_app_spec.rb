require File.dirname(__FILE__) + '/../spec_helper'

class Testoast
  include Dragonfly::BelongsToApp
end

describe Dragonfly::BelongsToApp do
  
  before(:each) do
    @object = Testoast.new
  end
  
  it "should raise an error if the app is accessed but not set" do
    lambda{
      @object.app
    }.should raise_error(Dragonfly::BelongsToApp::NotConfigured)
  end

  describe "when the app is set" do
    before(:each) do
      @app = Dragonfly::App[:test]
      @object.app = @app
    end
    
    it "should return the app" do
      @object.app.should == @app
    end
    
    it "should return the app's log" do
      @object.log.should == @app.log
    end

  end
  
end