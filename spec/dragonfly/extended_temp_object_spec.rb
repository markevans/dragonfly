require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::ExtendedTempObject do
  
  it "should raise an error if not configured with an app" do
    temp_object = Dragonfly::ExtendedTempObject.new('asdf')
    lambda{
      temp_object.process(:dummy)
    }.should raise_error(Dragonfly::ExtendedTempObject::NotConfiguredError)
  end
  
  describe "when configured correctly" do
    
    before(:each) do
      @analyser = mock('analyser', :has_delegatable_method? => false)
      @analyser.stub!(:has_delegatable_method?).with(:width).and_return(true)
      @processor = mock('processor')
      @encoder = mock('encoder')
      @app = mock('app', :analysers => @analyser, :processors => @processor, :encoders => @encoder)
      @klass = Class.new(Dragonfly::ExtendedTempObject)
      @klass.app = @app
    end
    
    describe "analysis" do

      before(:each) do
        @object = @klass.new('asdf')
      end
      
      it "should respond to something that the analyser responds to" do
        @analyser.should_receive(:has_delegatable_method?).with(:some_method).and_return(true)
        @object.should respond_to(:some_method)
      end
      
      it "should not respond to something that the analyser doesn't respond to" do
        @analyser.should_receive(:has_delegatable_method?).with(:some_method).and_return(false)
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
    
    describe "encoding" do
      before(:each) do
        @temp_object = @klass.new('abcde')
      end
      
      it "should encode the data and return the new temp object" do
        @encoder.should_receive(:encode).with(@temp_object, :some_format, :some => 'option').and_return('ABCDE')
        new_temp_object = @temp_object.encode(:some_format, :some => 'option')
        new_temp_object.data.should == 'ABCDE'
      end
      it "should encode its own data" do
        @encoder.should_receive(:encode).with(@temp_object, :some_format, :some => 'option').and_return('ABCDE')
        @temp_object.encode!(:some_format, :some => 'option')
        @temp_object.data.should == 'ABCDE'
      end
    end
    
  end
  
end