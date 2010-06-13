require File.dirname(__FILE__) + '/../spec_helper'

# Matchers
def have_steps(steps)
  simple_matcher("have steps #{steps.inspect}") do |given|
    given.steps.map{|step| step.class } == steps
  end
end


describe Dragonfly::Job do
  
  before(:each) do
    @app = mock_app
  end
  
  describe "without temp_object" do
    
    describe "fetch" do
      before(:each) do
        @job = Dragonfly::Job.new(@app)
        @job.fetch('some_uid')
      end

      it { @job.should have_steps([Dragonfly::Job::Fetch]) }

      it "should retrieve from the app's datastore when applied" do
        @app.datastore.should_receive(:retrieve).with('some_uid').and_return('HELLO')
        @job.apply
        @job.temp_object.data.should == 'HELLO'
      end
    end
    
  end
  
  describe "with temp_object already there" do
    
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('HELLO')
      @job = Dragonfly::Job.new(@app, @temp_object)
    end
    
    describe "process" do
      before(:each) do
        @job.process(:resize, '20x30')
      end

      it { @job.should have_steps([Dragonfly::Job::Process]) }

      it "should use the processor when applied" do
        @app.processors.should_receive(:resize).with(@temp_object, '20x30').and_return('hi')
        @job.apply
        @job.temp_object.data.should == 'hi'
      end
    end

    describe "encode" do
      before(:each) do
        @job.encode(:gif, :bitrate => 'mumma')
      end

      it { @job.should have_steps([Dragonfly::Job::Encoding]) }

      it "should use the encoder when applied" do
        @app.encoders.should_receive(:encode).with(@temp_object, :gif, :bitrate => 'mumma').and_return('alo')
        @job.apply
        @job.temp_object.data.should == 'alo'
      end
    end

  end
  
  it "should allow for defining more complicated jobs" do
    job = Dragonfly::Job.new(@app)
    job.fetch 'some_uid'
    job.process :thump
    job.encode :gip
    
    job.should have_steps([
      Dragonfly::Job::Fetch,
      Dragonfly::Job::Process,
      Dragonfly::Job::Encoding
    ])
  end
  
  describe "adding jobs" do
    it "should concatenate jobs" do
      job1 = Dragonfly::Job.new(@app)
      job1.process :resize
      job2 = Dragonfly::Job.new(@app)
      job2.encode :png
      
      job3 = job1 + job2
      job3.should have_steps([
        Dragonfly::Job::Process,
        Dragonfly::Job::Encoding
      ])
    end
  end
  
end
