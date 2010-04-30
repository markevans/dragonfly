require File.dirname(__FILE__) + '/../spec_helper'

class CarDriver
  include Dragonfly::Delegatable

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
  include Dragonfly::BelongsToApp
  include Dragonfly::Delegatable

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
  include Dragonfly::Delegatable
  include Dragonfly::Configurable

  configurable_attr :height

  def initialize(age); @age = age; end
  def age; @age; end
end

describe Dragonfly::Delegator do
  
  before(:each) do
    @delegator = Object.new
    @delegator.extend Dragonfly::Delegator
  end
  
  describe "when no items have been registered" do

    it "should raise an error when calling an unknown method" do
      lambda{ @delegator.drive }.should raise_error(NoMethodError)
    end

    it "should should return delegatable_methods as an empty array" do
      @delegator.delegatable_methods.should == []
    end
    
    it "should return the object registered when registering" do
      @delegator.register(CarDriver).should be_a(CarDriver)
    end
    
  end

  describe "after registering a number of classes" do

    before(:each) do
      @delegator.app = Dragonfly::App[:test]
      @car_driver = @delegator.register(CarDriver)
      @lorry_driver = @delegator.register(LorryDriver)
    end

    it "should raise an error when calling an unknown method" do
      lambda{ @delegator.swim }.should raise_error(NoMethodError)
    end

    it "should correctly delegate when only one item implements the method" do
      @delegator.open_boot.should == :open_boot
      @delegator.open_back_doors.should == :open_back_doors
    end

    it "should allow delegating explicitly" do
      @delegator.delegate(:open_boot).should == :open_boot
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

    it "should return registered objects" do
      @delegator.registered_objects.should == [@car_driver, @lorry_driver]
    end
    
    it "should set the registered object's app to its own if object should belong to an app" do
      @lorry_driver.app.should == @delegator.app
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