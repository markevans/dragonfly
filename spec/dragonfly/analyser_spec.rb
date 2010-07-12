require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Analyser do
  
  before(:each) do
    @analyser = Dragonfly::Analyser.new
  end
  
  describe "analysis_methods module" do
    
    before(:each) do
      @analyser.add(:width){|temp_object| temp_object.size }
      @obj = Object.new
      @obj.extend @analyser.analysis_methods
    end
    
    it "should return a module" do
      @analyser.analysis_methods.should be_a(Module)
    end
    
    it "should provide the object with the analyser" do
      @obj.analyser.should == @analyser
    end
    
    it "should pass the object returned by to_temp_object to the analyser" do
      @obj.should_receive(:to_temp_object).and_return Dragonfly::TempObject.new("HELLO")
      @obj.width.should == 5
    end
    
  end
  
end
