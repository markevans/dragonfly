require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::JobManager do
  
  describe "defining jobs" do
    
    before(:each) do
      @job_manager = Dragonfly::JobManager.new
    end
    
    it "should raise an error if not matched" do
      lambda{ @job_manager.job_for(:egg) }.should raise_error(Dragonfly::JobManager::JobNotFound)
    end
    
    describe "defining a simple processing job" do
      before(:each) do
        @job_manager.define_job :thumb do
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
        @job_manager.define_job :enc do
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

    describe "defining a multi-step job" do
      before(:each) do
        @job_manager.define_job :bubble do
          process :one
          encode :two
        end
        @job = @job_manager.job_for(:bubble)
      end
      it("should have the correct step types") do
        @job.steps.map(&:class).should == [Dragonfly::Job::Process, Dragonfly::Job::Encoding]
      end
    end

    describe "jobs with arguments" do
      before(:each) do
        @job_manager.define_job :thumb do |geometry, scoobie|
          process :resize, geometry, scoobie
        end
      end
      
      it "should yield args to the block" do
        job = @job_manager.job_for(:thumb, '30x50', :yum)
        
        process_step = job.steps.first
        process_step.name.should == :resize
        process_step.args.should == ['30x50', :yum]
      end
      
      it "default args to nil" do
        job = @job_manager.job_for(:thumb, '30x50!')
        job.steps.first.args.should == ['30x50!', nil]
      end
      
    end

    describe "calling other jobs inside a job definition" do
      before(:each) do
        @job_manager.define_job :terry do |size|
          process :resize, size
        end
        @job_manager.define_job :butcher do
          process :black_and_white
          job :terry, '100x100'
          encode :gif
        end
      end
      it "should correctly add the steps from the other job" do
        job = @job_manager.job_for(:butcher)
        
        process1, process2, encoding = job.steps
        process1.name.should == :black_and_white
        process2.name.should == :resize
        process2.args.should == ['100x100']
        encoding.format.should == :gif
      end
    end

  end

end