require File.dirname(__FILE__) + '/../spec_helper'

class TestLoggable
  include Dragonfly::Loggable
end

describe Dragonfly::Loggable do
  
  before(:each) do
    @object = TestLoggable.new
  end
  
  it "should return a log by default" do
    @object.log.should be_a(::Logger)
  end
  
  it "should be settable to a new log" do
    logger = Logger.new(STDOUT)
    @object.log = logger
    @object.log.should == logger
  end
  
end