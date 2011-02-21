require 'spec_helper'

RSpec::Matchers.define :have_keys do |*keys|
  match do |given|
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
        @fm.objects.length.should eql(1)
        @fm.objects.first.should be_a(@class)
      end
      
      it "should work when calling" do
        @fm.call_last(:doogie, 3).should == "eggheads 3"
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
      @fm.call_last(:height_and_age).should == [183, 43]
    end
    
    it "should run configure if a block given" do
      @fm.register(@class){|c| c.height = 180 }
      @fm.call_last(:height_and_age).should == [180, 6]
    end
    
    it "should not include configurable methods in the functions" do
      @fm.functions.keys.should == [:height_and_age]
    end
  end

  describe "calling" do

    describe "errors" do
      it "should raise an error for call_last if the function doesn't exist" do
        lambda{
          @fm.call_last(:i_dont_exist)
        }.should raise_error(Dragonfly::FunctionManager::NotDefined)
      end
      
      it "should raise an error if the function is defined but unable to handle" do
        @fm.add(:chicken){ throw :unable_to_handle }
        lambda{
          @fm.call_last(:chicken)
        }.should raise_error(Dragonfly::FunctionManager::UnableToHandle)
      end
    end

    describe "simple" do
      it "should correctly call a registered block" do
        @fm.add(:egg){|num| num + 1 }
        @fm.call_last(:egg, 4).should == 5
      end
      it "should correctly call a registered class" do
        klass = Class.new do
          def dog(num)
            num * 2
          end
        end
        @fm.register(klass)
        @fm.call_last(:dog, 4).should == 8
      end
      it "should correctly call an object that responds to 'call'" do
        obj = Object.new
        def obj.call(num); num - 3; end
        @fm.add(:spoon, obj)
        @fm.call_last(:spoon, 4).should == 1
      end
    end

    describe "with more than one implementation of same function" do
      it "should use the last registered" do
        @fm.add(:bingo){|num| num + 1 }
        @fm.add(:bingo){|num| num - 1 }
        @fm.call_last(:bingo, 4).should == 3
      end
      
      it "should skip methods that throw :unable_to_handle" do
        @fm.add(:bingo){|num| num + 1 }
        @fm.add(:bingo){|num| throw :unable_to_handle }
        @fm.call_last(:bingo, 4).should == 5
      end
    end

  end

end
