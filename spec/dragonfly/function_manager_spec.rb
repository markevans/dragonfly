require File.dirname(__FILE__) + '/../spec_helper'

def have_keys(*keys)
  simple_matcher("have keys #{keys.join(', ')}") do |given|
    given.keys.map{|sym| sym.to_s }.sort == keys.map{|sym| sym.to_s }.sort
  end
end

describe Dragonfly::FunctionManager do
  
  before(:each) do
    @fm = Dragonfly::FunctionManager.new
  end

  describe "registering functions" do
    
    describe "registering procs" do

      let(:func){ proc{ "HELLO" } }
    
      it "should allow registering procs" do
        @fm.add :hello, func
        @fm.functions.should == {:hello => [func]}
      end
    
      it "should allow registering using block syntax" do
        @fm.add(:hello, &func)
        @fm.functions.should == {:hello => [func]}
      end

    end

    describe "registering classes" do

      before(:each) do
        @class = Class.new do
          def doogie(buff)
            "eggheads #{buff}"
          end
          def bumfries(smarmey)
            "sharkboy"
          end
        end
        @fm.register(@class)
      end

      it "should add the methods" do
        @fm.functions.should have_keys(:doogie, :bumfries)
      end
      
      it "should record the registered object" do
        @fm.objects.length.should == 1
        @fm.objects.first.should be_a(@class)
      end
      
      it "should work when calling" do
        @fm.call(:doogie, 3).should == "eggheads 3"
      end
      
      it "should return the object when registering" do
        @fm.register(@class).should be_a(@class)
      end

    end
    
  end

  describe "configuring on registration" do
    
    before(:each) do
      @class = Class.new do
        include Dragonfly::Configurable
        configurable_attr :height, 183
        def initialize(age=6)
          @age = age
        end
        def height_and_age
          [height, @age]
        end
      end
      @fm.register(@class)
    end

    it "should pass the args on register to the object initializer" do
      @fm.register(@class, 43)
      @fm.call(:height_and_age).should == [183, 43]
    end
    
    it "should run configure if a block given" do
      @fm.register(@class){|c| c.height = 180 }
      @fm.call(:height_and_age).should == [180, 6]
    end
    
    it "should not include configurable methods in the functions" do
      @fm.functions.keys.should == [:height_and_age]
    end
  end

  describe "after registering a number of classes" do

    before(:each) do
      pending
    end
    it "should raise an error when calling an unknown method" do
      lambda{ @delegator.swim }.should raise_error(NoMethodError)
    end

    it "should correctly delegate when only one item implements the method" do
      @delegator.open_boot.should == :open_boot
      @delegator.open_back_doors.should == :open_back_doors
    end

    it "should delegate to the last registered when more than one item implements the method" do
      @delegator.drive('fishmonger').should == "Driving lorry fishmonger"
    end

    it "should return all the callable methods" do
      @delegator.delegatable_methods.sort.should == %w(clean drive open_back_doors open_boot pick_up).map{|m| m.to_method_name }
    end
    
    it "should say if if has a callable method (as a string)" do
      @delegator.has_delegatable_method?('drive').should be_true
    end

    it "should say if if has a callable method (as a symbol)" do
      @delegator.has_delegatable_method?(:drive).should be_true
    end

    it "should skip methods that throw :unable_to_handle" do
      @delegator.clean('my car').should == "Cleaning my car"
    end
    
    it "should raise an error if nothing was able to handle it" do
      lambda{ @delegator.pick_up('my lorry') }.should raise_error(Dragonfly::Delegator::UnableToHandle)
    end

    it "should enable unregistering classes" do
      @delegator.unregister(LorryDriver)
      @delegator.registered_objects.map(&:class).should == [CarDriver]
    end
    
    it "should enable unregistering all" do
      @delegator.unregister_all
      @delegator.registered_objects.should == []
    end

  end
  
end