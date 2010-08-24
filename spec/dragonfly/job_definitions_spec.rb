require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::JobDefinitions do

  describe "defining jobs" do

    before(:each) do
      @job_definitions = Dragonfly::JobDefinitions.new
      @object = Object.new
      @object.extend @job_definitions
    end

    describe "a simple job" do

      before(:each) do
        @job_definitions.add :thumb do |size|
          process :thumb, size
        end
      end

      it "correctly call job steps" do
        @object.should_receive(:process).with(:thumb, '30x30#').and_return(job=mock)
        @object.thumb('30x30#').should == job
      end

      it "should correctly call job steps when bang is given" do
        @object.should_receive(:process!).with(:thumb, '30x30#').and_return(@object)
        @object.thumb!('30x30#').should == @object
      end

    end

  end
  
end
