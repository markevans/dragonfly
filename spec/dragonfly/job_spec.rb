require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Job do
  
  it "should define a single processing job" do
    job = Dragonfly::Job.new do
      process :resize, 300, 200
    end
    job.parts.size.should == 1

    process = job.parts.first
    process.name.should == :resize
    process.args.should == [300, 200]
  end
  
  it "should define a single encoding job" do
    job = Dragonfly::Job.new do
      encode :gif, :doobie, :bitrate => 128
    end
    job.parts.size.should == 1

    encoding = job.parts.first
    encoding.format.should == :gif
    encoding.args.should == [:doobie, {:bitrate => 128}]
  end
  
  it "should define a more complicated job" do
    job = Dragonfly::Job.new do
      process :doobie
      encode :png
      process :hello
      encode :gip
    end
    
    job.parts.map(&:class).should == [
      Dragonfly::Job::Process,
      Dragonfly::Job::Encoding,
      Dragonfly::Job::Process,
      Dragonfly::Job::Encoding
    ]
  end
  
  describe "adding jobs" do
    it "should add jobs into a more complex job" do
      job1 = Dragonfly::Job.new{ process :resize }
      job2 = Dragonfly::Job.new{ encode :png }
      
      job3 = job1 + job2
      job3.parts.map(&:class).should == [
        Dragonfly::Job::Process,
        Dragonfly::Job::Encoding
      ]
    end
  end
  
end
