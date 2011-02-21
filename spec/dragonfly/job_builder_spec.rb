require 'spec_helper'

describe Dragonfly::JobBuilder do

  describe "a multi-step job" do

    before(:each) do
      @job_builder = Dragonfly::JobBuilder.new do |size, format|
        process :thumb, size
        encode format unless format.nil?
      end
    end

    it "should correctly call job steps" do
      job = mock
      job.should_receive(:process).with(:thumb, '30x30#').and_return(job2=mock)
      job2.should_receive(:encode).with(:jpg).and_return(job3=mock)
      @job_builder.build(job, '30x30#', :jpg).should == job3
    end

    it "should work consistently with bang methods" do
      job = mock
      job.should_receive(:process!).with(:thumb, '30x30#').and_return(job)
      job.should_receive(:encode!).with(:jpg).and_return(job)
      @job_builder.build!(job, '30x30#', :jpg).should == job
    end

    it "should yield nil if the arg isn't passed in" do
      job = mock
      job.should_receive(:process).with(:thumb, '30x30#').and_return(job2=mock)
      job2.should_not_receive(:encode)
      @job_builder.build(job, '30x30#').should == job2
    end

  end
  
end
