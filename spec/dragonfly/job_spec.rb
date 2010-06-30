require File.dirname(__FILE__) + '/../spec_helper'

# Matchers
def match_steps(steps)
  simple_matcher("match steps #{steps.inspect}") do |given|
    given.map{|step| step.class } == steps
  end
end

describe Dragonfly::Job do
  
  before(:each) do
    @app = mock_app
  end
  
  describe "without temp_object" do

    before(:each) do
      @job = Dragonfly::Job.new(@app)
    end

    it "should allow initializing with content" do
      job = Dragonfly::Job.new(@app, 'eggheads')
      job.temp_object.data.should == 'eggheads'
    end

    describe "fetch" do
      before(:each) do
        @job.fetch('some_uid')
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Fetch]) }

      it "should retrieve from the app's datastore when applied" do
        @app.datastore.should_receive(:retrieve).with('some_uid').and_return('HELLO')
        @job.apply
        @job.temp_object.data.should == 'HELLO'
      end
    end
    
    describe "process" do
      it "should raise an error when applying" do
        @job.process(:resize, '20x30')
        lambda{
          @job.apply
        }.should raise_error(Dragonfly::Job::NothingToProcess)
      end
    end

    describe "encode" do
      it "should raise an error when applying" do
        @job.encode(:gif)
        lambda{
          @job.apply
        }.should raise_error(Dragonfly::Job::NothingToEncode)
      end
    end
    
    describe "analyse" do
      it "should raise an error" do
        lambda{
          @job.analyse(:width)
        }.should raise_error(Dragonfly::Job::NothingToAnalyse)
      end
    end
    
  end
  
  describe "with temp_object already there" do
    
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('HELLO')
      @job = Dragonfly::Job.new(@app)
      @job.temp_object = @temp_object
    end
    
    describe "apply" do
      it "should return the temp_object" do
        @job.apply.should be_a(Dragonfly::TempObject)
      end
    end
    
    describe "process" do
      before(:each) do
        @job.process(:resize, '20x30')
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Process]) }

      it "should use the processor when applied" do
        @app.processors.should_receive(:process).with(@temp_object, :resize, '20x30').and_return('hi')
        @job.apply.data.should == 'hi'
      end
    end

    describe "encode" do
      before(:each) do
        @job.encode(:gif, :bitrate => 'mumma')
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Encode]) }

      it "should use the encoder when applied" do
        @app.encoders.should_receive(:encode).with(@temp_object, :gif, :bitrate => 'mumma').and_return('alo')
        @job.apply.data.should == 'alo'
      end
    end
    
    describe "analyse" do
      it "should use the app's analyser to analyse the temp_object" do
        @app.analysers.should_receive(:analyse).with(@temp_object, :width)
        @job.analyse(:width)
      end
    end

  end
  
  it "should allow for defining more complicated jobs" do
    job = Dragonfly::Job.new(@app)
    job.fetch 'some_uid'
    job.process :thump
    job.encode :gip
    
    job.steps.should match_steps([
      Dragonfly::Job::Fetch,
      Dragonfly::Job::Process,
      Dragonfly::Job::Encode
    ])
  end
  
  describe "adding jobs" do
    
    it "should raise an error if the app is different" do
      job1 = Dragonfly::Job.new(@app)
      job2 = Dragonfly::Job.new(mock_app)
      lambda {
        job1 + job2
      }.should raise_error(Dragonfly::Job::AppDoesNotMatch)
    end

    describe "both belonging to the same app" do
      before(:each) do
        @job1 = Dragonfly::Job.new(@app, 'hello')
        @job1.process :resize
        @job2 = Dragonfly::Job.new(@app, 'hola')
        @job2.encode :png
      end
      
      it "should concatenate jobs" do
        job3 = @job1 + @job2
        job3.steps.should match_steps([
          Dragonfly::Job::Process,
          Dragonfly::Job::Encode
        ])
      end
    
      it "should raise an error if the second job has applied steps" do
        @job2.apply
        lambda {
          @job1 + @job2
        }.should raise_error(Dragonfly::Job::JobAlreadyApplied)
      end
      
      it "should not raise an error if the first job has applied steps" do
        @job1.apply
        lambda {
          @job1 + @job2
        }.should_not raise_error
      end
      
      it "should have the first job's temp_object" do
        (@job1 + @job2).temp_object.data.should == 'hello'
      end
      
      it "should have the correct applied steps" do
        @job1.apply
        (@job1 + @job2).applied_steps.should match_steps([
          Dragonfly::Job::Process
        ])
      end
      
      it "should have the correct pending steps" do
        @job1.apply
        (@job1 + @job2).pending_steps.should match_steps([
          Dragonfly::Job::Encode
        ])
      end
    end

  end
  
  describe "defining extra steps after applying" do
    before(:each) do
      @job = Dragonfly::Job.new(@app)
      @job.temp_object = Dragonfly::TempObject.new("hello")
      @job.process :resize
      @job.apply
      @job.encode :micky
    end
    it "should not call apply on already applied steps" do
      @job.steps[0].should_not_receive(:apply)
      @job.apply
    end
    it "should call apply on not yet applied steps" do
      @job.steps[1].should_receive(:apply)
      @job.apply
    end
    it "should return all steps" do
      @job.steps.should match_steps([
        Dragonfly::Job::Process,
        Dragonfly::Job::Encode
      ])
    end
    it "should return applied steps" do
      @job.applied_steps.should match_steps([
        Dragonfly::Job::Process
      ])
    end
    it "should return the pending steps" do
      @job.pending_steps.should match_steps([
        Dragonfly::Job::Encode
      ])
    end
    it "should not call apply on any steps when already applied" do
      @job.apply
      @job.steps[0].should_not_receive(:apply)
      @job.steps[1].should_not_receive(:apply)
      @job.apply
    end
  end
  
  describe "to_a" do
    it "should represent all the steps in array form" do
      job = Dragonfly::Job.new(@app)
      job.fetch 'some_uid'
      job.process :resize, '30x40'
      job.encode :gif, :bitrate => 20
      job.to_a.should == [
        [:f, 'some_uid'],
        [:p, :resize, '30x40'],
        [:e, :gif, {:bitrate => 20}]
      ]
    end
  end
  
  describe "from_a" do
    before(:each) do
      @job = Dragonfly::Job.from_a([
        [:f, 'some_uid'],
        [:p, :resize, '30x40'],
        [:e, :gif, {:bitrate => 20}]
      ], @app)
    end
    it "should have the correct step types" do
      @job.steps.should match_steps([
        Dragonfly::Job::Fetch,
        Dragonfly::Job::Process,
        Dragonfly::Job::Encode
      ])
    end
    it "should have the correct args" do
      @job.steps[0].args.should == ['some_uid']
      @job.steps[1].args.should == [:resize, '30x40']
      @job.steps[2].args.should == [:gif, {:bitrate => 20}]
    end
    it "should have no applied steps" do
      @job.applied_steps.should be_empty
    end
    it "should have all steps pending" do
      @job.steps.should == @job.pending_steps
    end
  end
  
  describe "format" do
    before(:each) do
      @job = Dragonfly::Job.new(@app)
    end
    it "should return nil if no encoding steps have been defined" do
      @job.format.should be_nil
    end
    it "should return the format of the last encoding step" do
      @job.encode :gif
      @job.process :resize, '30x30'
      @job.encode :png
      @job.process :resize, '50x50'
      @job.format.should == :png
    end
  end
  
  describe "mime_type" do
    before(:each) do
      @job = Dragonfly::Job.new(@app)
    end
    it "should return nil if no encoding steps have been defined" do
      @job.mime_type.should be_nil
    end
    it "should get the mime_type of the last encoding step from the app" do
      @job.encode :png
      @app.should_receive(:mime_type_for).with(:png).and_return 'image/png'
      @job.mime_type.should == 'image/png'
    end
  end
  
end
