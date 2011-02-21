require 'spec_helper'

describe Dragonfly::Analyser do
  
  before(:each) do
    @analyser = Dragonfly::Analyser.new
    @analyser.log = Logger.new(LOG_FILE)
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
      @temp_object = Dragonfly::TempObject.new('HELLO')
    end

    def it_should_analyse_using(meth, temp_object, *args)
      result = mock('result')
      @analyser.should_receive(:call_last).with(meth, temp_object, *args).exactly(:once).and_return result
      @analyser.analyse(temp_object, meth, *args).should == result
      result
    end

    it "should do the analysis the first time" do
      it_should_analyse_using(:blah, @temp_object, :arg1)
    end

    describe "when already called" do
      before(:each) do
        @result = it_should_analyse_using(:blah, @temp_object, :arg1)
      end

      it "should not do it subsequent times but still return the result" do
        @analyser.should_not_receive(:call_last)
        @analyser.analyse(@temp_object, :blah, :arg1).should == @result
        @analyser.analyse(@temp_object, :blah, :arg1).should == @result
      end
      
      it "should not use the cache if the temp_object is different" do
        temp_object = Dragonfly::TempObject.new('aaa')
        it_should_analyse_using(:blah, temp_object, :arg1)
      end
      
      it "should not use the cache if the method name is different" do
        it_should_analyse_using(:egghead, @temp_object, :arg1)
      end
      
      it "should not use the cache if the args are different" do
        it_should_analyse_using(:blah, @temp_object, :arg2)
      end
      
      it "should do it again if the cache has been cleared" do
        @analyser.clear_cache!
        it_should_analyse_using(:blah, @temp_object, :arg1)
      end

      it "should not use the cache if it has been turned off" do
        @analyser.enable_cache = false
        it_should_analyse_using(:blah, @temp_object, :arg1)
      end
      
    end

    describe "cache size" do
      it "should not exceed the cache size" do
        @analyser.cache_size = 2

        res1 = it_should_analyse_using(:blah, @temp_object, :arg1)
        res2 = it_should_analyse_using(:blah, @temp_object, :arg2)
        res3 = it_should_analyse_using(:blah, @temp_object, :arg3) # Should kick out first one
        
        it_should_analyse_using(:blah, @temp_object, :arg1)

        # Third analysis should still be cached
        @analyser.should_not_receive(:call_last)
        @analyser.analyse(@temp_object, :blah, :arg3).should == res3
      end
    end

  end
  
end
