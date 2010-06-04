require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::ExtendedTempObject do
  
  describe "when configured correctly" do
    
    before(:each) do
      @app = Dragonfly::App[:test]
    end
    
    describe "analysis" do

      before(:each) do
        analyser_class = Class.new(Dragonfly::Analysis::Base) do
          def width(temp_object); temp_object.data.size; end
        end
        @analyser = @app.register_analyser(analyser_class)
        @object = Dragonfly::ExtendedTempObject.new(@app, 'asdf')
      end
      
      it "should respond to something that the analyser responds to" do
        @object.should respond_to(:width)
      end
      
      it "should not respond to something that the analyser doesn't respond to" do
        @object.should_not respond_to(:spaghetti)
      end

      it "should delegate the analysis to the analyser" do
        @object.width.should == 4
      end
      
      it "should cache the result so that it doesn't call it a second time" do
        @analyser.should_receive(:width).with(@object).and_return(4)
        @object.width.should == 4
        @analyser.should_not_receive(:width)
        @object.width.should == 4
      end
      
      it "should do the analysis again when it has been modified" do
        @object.width.should == 4
        @object.modify_self!('hellothisisnew')
        @object.width.should == 14
        @analyser.should_not_receive(:width)
        @object.width.should == 14
      end
      
    end
  
  end
end