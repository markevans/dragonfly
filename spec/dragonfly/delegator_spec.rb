require File.dirname(__FILE__) + '/../spec_helper'

class CarDriver
  def drive(car)
    "Driving car #{car}"
  end
  def open_boot
    :open_boot
  end
  def clean(car)
    "Cleaning #{car}"
  end
end

class LorryDriver
  def drive(lorry)
    "Driving lorry #{lorry}"
  end
  def open_back_doors
    :open_back_doors
  end
  def clean(lorry)
    throw :unable_to_handle
  end
  def pick_up(lorry)
    throw :unable_to_handle
  end
end

class BusDriver
  include Dragonfly::Configurable
  configurable_attr :height
  def initialize(age); @age = age; end
  def age; @age; end
end

describe Dragonfly::Delegator do
  
  before(:each) do
    @delegator = Dragonfly::Delegator.new
  end
  
  describe "when no items have been registered" do

    it "should raise an error when calling an unknown method" do
      lambda{ @delegator.drive }.should raise_error(NoMethodError)
    end

    it "should should return callable_methods as an empty array" do
      @delegator.callable_methods.should == []
    end
    
  end

  describe "after registering a number of classes" do

    before(:each) do
      @delegator.register(CarDriver)
      @delegator.register(LorryDriver)
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
      @delegator.callable_methods.sort.should == %w(clean drive open_back_doors open_boot pick_up)
    end
    
    it "should say if if has a callable method (as a string)" do
      @delegator.has_callable_method?('drive').should be_true
    end

    it "should say if if has a callable method (as a symbol)" do
      @delegator.has_callable_method?(:drive).should be_true
    end

    it "should skip methods that throw :unable_to_handle" do
      @delegator.clean('my car').should == "Cleaning my car"
    end
    
    it "should raise an error if nothing was able to handle it" do
      lambda{ @delegator.pick_up('my lorry') }.should raise_error(Dragonfly::Delegator::UnableToHandle)
    end

    it "should return registered objects" do
      objects = @delegator.registered_objects
      objects.length.should == 2
      objects[0].should be_a(CarDriver)
      objects[1].should be_a(LorryDriver)
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
  
  describe "configuring on registration" do
    it "should pass the args on register to the object initializer" do
      @delegator.register(BusDriver, 43)
      @delegator.age.should == 43
    end
    
    it "should run configure if a block given" do
      @delegator.register(BusDriver, 43){|c| c.height = 180 }
      @delegator.height.should == 180
    end
  end
  
  
end