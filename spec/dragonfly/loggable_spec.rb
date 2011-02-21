require 'spec_helper'

class Testoast
  include Dragonfly::Loggable
end

describe Dragonfly::Loggable do
  
  before(:each) do
    @object = Testoast.new
  end

  shared_examples_for "common" do
    it "should return a log" do
      @object.log.should be_a(Logger)
    end
    it "should cache the log" do
      @object.log.should == @object.log
    end
  end

  describe "without being set" do
    it "should return the log object as nil" do
      @object.log_object.should be_nil
    end
    it_should_behave_like 'common'
  end

  describe "when set" do
    before(:each) do
      @log = Logger.new($stdout)
      @object.log = @log
    end
    it "should return the new log" do
      @object.log.should == @log
    end
    it "should return the log object" do
      @object.log_object.should == @log
    end
    it_should_behave_like 'common'
  end

  describe "when set as a proc" do
    before(:each) do
      @log = Logger.new($stdout)
      @object.log = proc{ @log }
    end
    it "should return the new log" do
      @object.log.should == @log
    end
    it "should return the log object" do
      @object.log_object.should be_a(Proc)
    end
    it "should allow for changing logs" do
      logs = [@log]
      @object.log = proc{ logs[0] }
      @object.log.should == @log
      
      new_log = Logger.new($stdout)
      logs[0] = new_log
      
      @object.log.should == new_log
    end
    it_should_behave_like 'common'
  end
  
  describe "sharing logs" do
    before(:each) do
      @log = Logger.new($stdout)
      @obj1 = Testoast.new
      @obj2 = Testoast.new
    end
    it "should enable sharing logs" do
      @obj1.log = proc{ @log }
      @obj2.use_same_log_as(@obj1)
      @obj2.log.should == @log
    end
  end

end
