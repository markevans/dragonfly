require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::JobManager do
  
  describe "defining jobs" do
    
    before(:each) do
      @job_manager = Dragonfly::JobManager.new
    end
    
    describe "defining a simple processing job" do
      before(:each) do
        @job_manager.define_job :thumb do |sym|
          process :resize, 300, 200
        end
        @job = @job_manager.job_for(:thumb)
        @step = @job.steps[0]
      end
      it("should have the correct num_steps"){ @job.num_steps.should == 1 }
      it("should have the correct step type"){ @step.should be_a(Dragonfly::Job::Process) }
      it("should have the correct name"){ @step.name.should == :resize }
      it("should have the correct args"){ @step.args.should == [300, 200] }
    end

    describe "defining a simple encoding job" do
      before(:each) do
        @job_manager.define_job :enc do |sym|
          encode :gif, :bitrate => 128
        end
        @job = @job_manager.job_for(:enc)
        @step = @job.steps[0]
      end
      it("should have the correct num_steps"){ @job.num_steps.should == 1 }
      it("should have the correct step type"){ @step.should be_a(Dragonfly::Job::Encoding) }
      it("should have the correct format"){ @step.format.should == :gif }
      it("should have the correct args"){ @step.args.should == [{:bitrate => 128}] }
    end

    it "should return nil if not matched" do
      @job_manager.define_job :thumb do |sym|
        process :resize, 300, 200
      end
      @job_manager.job_for(:egg).should be_nil
    end

  end

end