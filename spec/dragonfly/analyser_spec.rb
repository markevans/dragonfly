require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Analyser do
  
  before(:each) do
    @analyser = Dragonfly::Analyser.new
  end
  
  describe "analysis_methods module" do
    
    before(:each) do
      @analyser.add(:num_letters){|temp_object, letter| temp_object.data.count(letter) }
      @obj = Object.new
      @obj.extend @analyser.analysis_methods
    end
    
    it "should return a module" do
      @analyser.analysis_methods.should be_a(Module)
    end
    
    it "should provide the object with the analyser method" do
      @obj.analyser.should == @analyser
    end
    
    it "should provide the object with the direct analysis method, provided that analyse method exists" do
      def @obj.analyse(meth, *args)
        analyser.analyse Dragonfly::TempObject.new('HELLO'), meth, *args
      end
      @obj.num_letters('L').should == 2
    end
    
  end
  
  describe "analyse" do
    it "should return nil if the function isn't defined" do
      @analyser.analyse(Dragonfly::TempObject.new("Hello"), :width).should be_nil
    end
    it "should return nil if the function can't be handled" do
      @analyser.add(:width){ throw :unable_to_handle }
      @analyser.analyse(Dragonfly::TempObject.new("Hello"), :width).should be_nil
    end
  end
  
  describe "analysis_method_names" do
    it "should return the analysis methods" do
      @analyser.add(:width){}
      @analyser.add(:height){}
      @analyser.analysis_method_names.should == [:width, :height]
    end
  end
  
end
