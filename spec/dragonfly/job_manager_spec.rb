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

    describe "matching arguments" do
      before(:each) do
        @job_manager.define_job /^\d+x\d+$/, Symbol do |geometry, scoobie|
          process :resize, geometry, scoobie
        end
      end
      
      it "should match args and yield them to the block" do
        job = @job_manager.job_for('30x50', :yum)
        
        process_step = job.steps.first
        process_step.name.should == :resize
        process_step.args.should == ['30x50', :yum]
      end
      
      it "should not match if the args don't all match" do
        lambda{
          @job_manager.job_for('30x50!', :yum)
        }.should raise_error(Dragonfly::JobManager::JobNotFound)
      end
      
      it "should raise an error if the args match but have the wrong number of args" do
        lambda{
          @job_manager.job_for('30x50', :yum, :innit_man)
        }.should raise_error(Dragonfly::JobManager::JobNotFound)
      end

      it "should let later shortcuts have priority over earlier ones" do
        @job_manager.define_job /^\d+x\d+$/, Symbol do |geometry, scoobie|
          process :crop_and_resize, geometry, scoobie
        end
        @job_manager.job_for('30x50', :gif).steps.first.name.should == :crop_and_resize
      end
      
    end

    describe "calling other jobs inside a job definition" do
      before(:each) do
        pending
        @job_manager.define_job :terry do
          process :resize, '50x50'
        end
        @job_manager.define_job :butcher do
          process :black_and_white
          job :terry
        end
      end
      it "should correctly add the steps from the other job" do
        job = @job_manager.job_for(:butcher)
        job.steps.map(&:name).should == [:black_and_white, :resize]
      end
    end

  end

end