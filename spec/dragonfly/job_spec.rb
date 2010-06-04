require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::Job do
  
  let(:app){ mock('app') }
  
  it "should define a single processing job" do
    job = Dragonfly::Job.new(app)
    job.process :resize, 300, 200
    
    job.num_steps.should == 1

    process = job.steps.first
    process.name.should == :resize
    process.arguments.should == [300, 200]
  end
  
  it "should define a single encoding job" do
    job = Dragonfly::Job.new(app)
    job.encode :gif, :doobie, :bitrate => 128
    
    job.num_steps.should == 1

    encoding = job.steps.first
    encoding.format.should == :gif
    encoding.arguments.should == [:doobie, {:bitrate => 128}]
  end
  
  it "should allow for defining more complicated jobs" do
    job = Dragonfly::Job.new(app)
    job.process :doobie
    job.encode :png
    job.process :hello
    job.encode :gip
    
    job.should match_job([
      [:process, :doobie],
      [:encoding, :png],
      [:process, :hello],
      [:encoding, :gip]
    ])
  end
  
  describe "adding jobs" do
    it "should concatenate jobs" do
      job1 = Dragonfly::Job.new(app)
      job1.process :resize
      job2 = Dragonfly::Job.new(app)
      job2.encode :png
      
      job3 = job1 + job2
      job3.should match_job([
        [:process, :resize],
        [:encoding, :png]
      ])
    end
  end
  
  describe "applying a job" do
    
    before(:each) do
      @app = Dragonfly::App[:asdfe]
    end
    
    describe "encoding" do
      before(:each) do
        encoder_class = Class.new(Dragonfly::Encoding::Base)
        @encoder = @app.register_encoder(encoder_class)
        @temp_object = Dragonfly::TempObject.new('abcde')
        @job = Dragonfly::Job.new(@app, @temp_object)
      end

      it "should encode the data and return the new temp object" do
        @encoder.should_receive(:encode).with(@temp_object, :some_format, :some => 'option').and_return('ABCDE')
        @job.encode(:some_format, :some => 'option').data.should == 'ABCDE'
      end
    end

  end
  
end
