require 'spec_helper'

describe Dragonfly::ProcessorBuilder do

  describe "a multi-step job" do

    before(:each) do
      @processor_builder = Dragonfly::ProcessorBuilder.new do |size, format|
        process :thumb, size
        process :encode, format unless format.nil?
      end
    end

    it "should correctly call process job steps" do
      job = mock
      job.should_receive(:process).with(:thumb, '30x30#').and_return(job2=mock)
      job2.should_receive(:process).with(:encode, :jpg).and_return(job3=mock)
      @processor_builder.build(job, '30x30#', :jpg).should == job3
    end

    it "should work consistently with bang methods" do
      job = mock
      job.should_receive(:process!).with(:thumb, '30x30#').and_return(job)
      job.should_receive(:process!).with(:encode, :jpg).and_return(job)
      @processor_builder.build!(job, '30x30#', :jpg).should == job
    end

    it "should yield nil if the arg isn't passed in" do
      job = mock
      job.should_receive(:process).with(:thumb, '30x30#').and_return(job2=mock)
      job2.should_not_receive(:process).with(:encode, :jpg)
      @processor_builder.build(job, '30x30#').should == job2
    end

  end

end
