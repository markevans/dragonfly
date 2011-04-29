require 'spec_helper'

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
  
  
  describe "#jobs" do
    
    before(:each) do
      @job_definitions = Dragonfly::JobDefinitions.new
      @object = Object.new
      @object.extend @job_definitions
    end
    
    it "should provide an empty list when no jobs have been definded" do
      jobs = @job_definitions.jobs
      jobs.should be_an Array
      jobs.should be_empty
    end
    
    it "should contain the job name when one is defined" do
      job_name = :foo
      @job_definitions.add job_name do |size|
        process :thumb, size
      end
      
      @job_definitions.jobs.should eq [job_name]
    end
    
  end
  
end
