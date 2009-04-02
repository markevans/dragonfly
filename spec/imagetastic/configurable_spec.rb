require File.dirname(__FILE__) + '/../spec_helper'

class Car
  extend Imagetastic::Configurable

  configurable_attr :colour
  configurable_attr :top_speed, 216

end

describe Car do

  it "should provide attr_readers for configurable attributes" do
    Car.should respond_to(:colour)
  end
  
  it "should not provide attr_writers for configurable attributes" do
    Car.should_not respond_to(:colour=)
  end
  
  it "should set default values for configurable attributes" do
    Car.top_speed.should == 216
  end
  
  it "should set the default as nil if not specified" do
    Car.colour.should be_nil
  end

end