require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::ExtendedTempObject do
  
  it "should raise an error if not configured with an app" do
    temp_object = Imagetastic::ExtendedTempObject.new('asdf')
    lambda{
      temp_object.process(:dummy)
    }.should raise_error(Imagetastic::ExtendedTempObject::NotConfiguredError)
  end
  
  describe "when configured correctly" do
    
    before(:each) do
      @analyser = mock('analyser')
      @processor = mock('processor')
      @encoder = mock('encoder')
      @app = mock('app', :analyser => @analyser, :processor => @processor, :encoder => @encoder)
      @klass = Class.new(Imagetastic::ExtendedTempObject)
      @klass.app = @app
      @object = @klass.new('asdf')
    end
    
    describe "analysis" do
      
      it "should respond to something that the analyser responds to" do
        @analyser.should_receive(:respond_to?).with(:some_method).and_return(true)
        @object.should respond_to(:some_method)
      end
      
      it "should not respond to something that the analyser doesn't respond to" do
        @analyser.should_receive(:respond_to?).with(:some_method).and_return(false)
        @object.should_not respond_to(:some_method)
      end

      it "should delegate the analysis to the analyser" do
        @analyser.should_receive(:width).with(@object).and_return(4)
        @object.width.should == 4
      end
      
      it "should cache the result so that it doesn't call it a second time" do
        @analyser.should_receive(:width).with(@object).and_return(4)
        @object.width.should == 4

        @analyser.should_not_receive(:width)
        @object.width.should == 4
      end
      
      it "should do the analysis again when it has been modified" do
        @analyser.should_receive(:width).with(@object).and_return(4)
        @object.width.should == 4
        
        @object.modify_self!('hellothisisnew')
        
        @analyser.should_receive(:width).with(@object).and_return(17)
        @object.width.should == 17
        
        @analyser.should_not_receive(:width)
        @object.width.should == 17
      end
      
    end
    
  end
  
end