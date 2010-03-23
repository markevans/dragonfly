require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Job do
  
  it "should define a single processing job" do
    job = Dragonfly::Job.new
    job.add_process :resize, 300, 200
    
    job.num_steps.should == 1

    process = job.steps.first
    process.name.should == :resize
    process.args.should == [300, 200]
  end
  
  it "should define a single encoding job" do
    job = Dragonfly::Job.new
    job.add_encoding :gif, :doobie, :bitrate => 128
    
    job.num_steps.should == 1

    encoding = job.steps.first
    encoding.format.should == :gif
    encoding.args.should == [:doobie, {:bitrate => 128}]
  end
  
  it "should allow for defining more complicated jobs" do
    job = Dragonfly::Job.new
    job.add_process :doobie
    job.add_encoding :png
    job.add_process :hello
    job.add_encoding :gip
    
    job.should match_job([
      [:process, :doobie],
      [:encoding, :png],
      [:process, :hello],
      [:encoding, :gip]
    ])
  end
  
  describe "adding jobs" do
    it "should concatenate jobs" do
      job1 = Dragonfly::Job.new
      job1.add_process :resize
      job2 = Dragonfly::Job.new
      job2.add_encoding :png
      
      job3 = job1 + job2
      job3.should match_job([
        [:process, :resize],
        [:encoding, :png]
      ])
    end
  end
  
  describe "performing a job" do
    before(:each) do
      @job = Dragonfly::Job.new
      @job.add_process :resize, '10x10'
      @job.add_encoding :png, :bitrate => 'loads'
    end
    it "should apply the steps to the temp_object" do
      temp_object = mock('temp_object')
      temp_object.should_receive(:process).with(:resize, '10x10').and_return(temp_object2=mock)
      temp_object2.should_receive(:encode).with(:png, :bitrate => 'loads').and_return(temp_object3=mock)
      @job.perform(temp_object).should == temp_object3
    end
  end
  
end
