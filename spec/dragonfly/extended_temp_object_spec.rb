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
        @object = Dragonfly::ExtendedTempObject.new('asdf', @app)
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
    
    describe "encoding" do
      before(:each) do
        encoder_class = Class.new(Dragonfly::Encoding::Base)
        @encoder = @app.register_encoder(encoder_class)
        @temp_object = Dragonfly::ExtendedTempObject.new('abcde', @app)
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