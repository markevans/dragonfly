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
  
  describe "cache" do
    before(:each) do
      @proc = proc{}
      @analyser.add(:blah, @proc)
      @temp_object = Dragonfly::TempObject.new('HELLO')
    end

    it "should do the analysis the first time" do
      @proc.should_receive(:call).with(@temp_object, :arg1).and_return(87)
      @analyser.analyse(@temp_object, :blah, :arg1).should == 87
    end

    describe "when already called" do
      before(:each) do
        @proc.should_receive(:call).with(@temp_object, :arg1).and_return(87)
        @analyser.analyse(@temp_object, :blah, :arg1).should == 87
      end

      it "should not do it subsequent times but still return the result" do
        @proc.should_not_receive(:call)
        @analyser.analyse(@temp_object, :blah, :arg1).should == 87
        @analyser.analyse(@temp_object, :blah, :arg1).should == 87
      end
      
      it "should not use the cache if the temp_object is different" do
        temp_object = Dragonfly::TempObject.new('aaa')
        @proc.should_receive(:call).with(temp_object, :arg1).and_return(41)
        @analyser.analyse(temp_object, :blah, :arg1).should == 41
      end
      
      it "should not use the cache if the method name is different" do
        new_proc = proc{}
        @analyser.add(:egghead, new_proc)
        @proc.should_not_receive(:call)
        new_proc.should_receive(:call).with(@temp_object, :arg1).and_return(88)
        @analyser.analyse(@temp_object, :egghead, :arg1).should == 88
      end
      
      it "should not use the cache if the args are different" do
        @proc.should_receive(:call).with(@temp_object, :arg2).and_return(92)
        @analyser.analyse(@temp_object, :blah, :arg2).should == 92
      end
      
      it "should do it again if the cache has been cleared" do
        @analyser.clear_cache!
        @proc.should_receive(:call).with(@temp_object, :arg1).and_return(87)
        @analyser.analyse(@temp_object, :blah, :arg1).should == 87
      end

      it "should not use the cache if it has been turned off" do
        @analyser.enable_cache = false
        @proc.should_receive(:call).with(@temp_object, :arg1).and_return(87)
        @analyser.analyse(@temp_object, :blah, :arg1).should == 87
      end
    end
  end
  
end
