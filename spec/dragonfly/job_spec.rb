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
    
    job.steps.map(&:class).should == [
      Dragonfly::Job::Process,
      Dragonfly::Job::Encoding,
      Dragonfly::Job::Process,
      Dragonfly::Job::Encoding
    ]
  end
  
  describe "adding jobs" do
    it "should concatenate jobs" do
      job1 = Dragonfly::Job.new
      job1.add_process :resize
      job2 = Dragonfly::Job.new
      job2.add_encoding :png
      
      job3 = job1 + job2
      job3.steps.map(&:class).should == [
        Dragonfly::Job::Process,
        Dragonfly::Job::Encoding
      ]
    end
  end
  
end
