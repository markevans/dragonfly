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
  
end
