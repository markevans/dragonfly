require File.dirname(__FILE__) + '/../spec_helper'

# Matchers
def match_steps(steps)
  simple_matcher("match steps #{steps.inspect}") do |given|
    given.map{|step| step.class } == steps
  end
end

describe Dragonfly::Job do
  
  describe "Step types" do
    
    {
      Dragonfly::Job::Fetch => :fetch,
      Dragonfly::Job::Process => :process,
      Dragonfly::Job::Encode => :encode,
      Dragonfly::Job::Generate => :generate
    }.each do |klass, step_name|
      it "should return the correct step name for #{klass}" do
        klass.step_name.should == step_name
      end
    end

    {
      Dragonfly::Job::Fetch => :f,
      Dragonfly::Job::Process => :p,
      Dragonfly::Job::Encode => :e,
      Dragonfly::Job::Generate => :g
    }.each do |klass, abbreviation|
      it "should return the correct abbreviation for #{klass}" do
        klass.abbreviation.should == abbreviation
      end
    end
    
    describe "step_names" do
      it "should return the available step names" do
        Dragonfly::Job.step_names.should == [:fetch, :process, :encode, :generate]
      end
    end

  end
  
  describe "without temp_object" do

    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app)
    end

    it "should allow initializing with content" do
      job = Dragonfly::Job.new(@app, Dragonfly::TempObject.new('eggheads'))
      job.temp_object.data.should == 'eggheads'
    end

    describe "fetch" do
      before(:each) do
        @job.fetch!('some_uid')
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Fetch]) }

      it "should retrieve from the app's datastore when applied" do
        @app.datastore.should_receive(:retrieve).with('some_uid').and_return('HELLO')
        @job.apply
        @job.temp_object.data.should == 'HELLO'
      end

      it "should set extra data if returned from the datastore" do
        @app.datastore.should_receive(:retrieve).with('some_uid').and_return(['HELLO', {:name => 'test.txt', :meta => {1=>2}}])
        @job.apply
        @job.temp_object.data.should == 'HELLO'
        @job.temp_object.name.should == 'test.txt'
        @job.temp_object.meta.should == {1 => 2}
      end
    end
    
    describe "process" do
      it "should raise an error when applying" do
        @job.process!(:resize, '20x30')
        lambda{
          @job.apply
        }.should raise_error(Dragonfly::Job::NothingToProcess)
      end
    end

    describe "encode" do
      it "should raise an error when applying" do
        @job.encode!(:gif)
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
    
    describe "generate" do
      before(:each) do
        @job.generate!(:plasma, 20, 30)
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Generate]) }

      it "should use the generator when applied" do
        @app.generator.should_receive(:generate).with(:plasma, 20, 30).and_return('hi')
        @job.apply.data.should == 'hi'
      end

      it "should save extra data if the generator returns it" do
        @app.generator.should_receive(:generate).with(:plasma, 20, 30).and_return(['hi', {:name => 'plasma.png', :format => :png, :meta => {:a => :b}}])
        @job.apply
        @job.temp_object.data.should == 'hi'
        @job.temp_object.name.should == 'plasma.png'
        @job.temp_object.format.should == :png
        @job.temp_object.meta.should == {:a => :b}
      end
    end
    
  end
  
  describe "with temp_object already there" do
    
    before(:each) do
      @app = mock_app
      @temp_object = Dragonfly::TempObject.new('HELLO', :name => 'hello.txt', :meta => {:a => :b})
      @job = Dragonfly::Job.new(@app)
      @job.temp_object = @temp_object
    end
    
    describe "apply" do
      it "should return itself" do
        @job.apply.should == @job
      end
    end
    
    describe "process" do
      before(:each) do
        @job.process!(:resize, '20x30')
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Process]) }

      it "should use the processor when applied" do
        @app.processor.should_receive(:process).with(@temp_object, :resize, '20x30').and_return('hi')
        @job.apply.data.should == 'hi'
      end

      it "should maintain the temp object attributes" do
        @app.processor.should_receive(:process).with(@temp_object, :resize, '20x30').and_return('hi')
        temp_object = @job.apply.temp_object
        temp_object.data.should == 'hi'
        temp_object.name.should == 'hello.txt'
        temp_object.meta.should == {:a => :b}
      end
    end

    describe "encode" do
      before(:each) do
        @job.encode!(:gif, :bitrate => 'mumma')
      end

      it { @job.steps.should match_steps([Dragonfly::Job::Encode]) }

      it "should use the encoder when applied" do
        @app.encoder.should_receive(:encode).with(@temp_object, :gif, :bitrate => 'mumma').and_return('alo')
        @job.apply.data.should == 'alo'
      end

      it "should maintain the temp object attributes" do
        @app.encoder.should_receive(:encode).with(@temp_object, :gif, :bitrate => 'mumma').and_return('alo')
        temp_object = @job.apply.temp_object
        temp_object.data.should == 'alo'
        temp_object.name.should == 'hello.txt'
        temp_object.meta.should == {:a => :b}
      end
    end
  end
  
  describe "analysis" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app, Dragonfly::TempObject.new('HELLO'))
      @app.analyser.add(:num_letters){|temp_object, letter| temp_object.data.count(letter) }
    end
    it "should return correctly when calling analyse" do
      @job.analyse(:num_letters, 'L').should == 2
    end
    it "should have mixed in the analyser method" do
      @job.num_letters('L').should == 2
    end
    it "should return nil from analyse if calling any old method" do
      @job.analyse(:robin_van_persie).should be_nil
    end
    it "should not allow calling any old method" do
      lambda{
        @job.robin_van_persie
      }.should raise_error(NoMethodError)
    end
    it "should work correctly with chained jobs, applying before analysing" do
      @app.processor.add(:double){|temp_object| temp_object.data * 2 }
      @job.process(:double).num_letters('L').should == 4
    end
  end

  describe "adding jobs" do
    
    before(:each) do
      @app = mock_app
    end
    
    it "should raise an error if the app is different" do
      job1 = Dragonfly::Job.new(@app)
      job2 = Dragonfly::Job.new(mock_app)
      lambda {
        job1 + job2
      }.should raise_error(Dragonfly::Job::AppDoesNotMatch)
    end

    describe "both belonging to the same app" do
      before(:each) do
        @job1 = Dragonfly::Job.new(@app, Dragonfly::TempObject.new('hello'))
        @job1.process! :resize
        @job2 = Dragonfly::Job.new(@app, Dragonfly::TempObject.new('hola'))
        @job2.encode! :png
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
      @app = mock_app
      @job = Dragonfly::Job.new(@app)
      @job.temp_object = Dragonfly::TempObject.new("hello")
      @job.process! :resize
      @job.apply
      @job.encode! :micky
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

  describe "chaining" do

    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app)
    end

    it "should return itself if bang is used" do
      @job.fetch!('some_uid').should == @job
    end

    it "should return a new job if bang is not used" do
      @job.fetch('some_uid').should_not == @job
    end

    describe "when a chained job is defined" do
      before(:each) do
        @job.fetch!('some_uid')
        @job2 = @job.process(:resize, '30x30')
      end

      it "should return the correct steps for the original job" do
        @job.applied_steps.should match_steps([
        ])
        @job.pending_steps.should match_steps([
          Dragonfly::Job::Fetch
        ])
      end

      it "should return the correct data for the original job" do
        @job.data.should == 'SOME_DATA'
      end

      it "should return the correct steps for the new job" do
        @job2.applied_steps.should match_steps([
        ])
        @job2.pending_steps.should match_steps([
          Dragonfly::Job::Fetch,
          Dragonfly::Job::Process
        ])
      end

      it "should return the correct data for the new job" do
        @job2.data.should == 'SOME_PROCESSED_DATA'
      end
      
      it "should not affect the other one when one is applied" do
        @job.apply
        @job.applied_steps.should match_steps([
          Dragonfly::Job::Fetch
        ])
        @job.pending_steps.should match_steps([
        ])
        @job.temp_object.data.should == 'SOME_DATA'
        @job2.applied_steps.should match_steps([
        ])
        @job2.pending_steps.should match_steps([
          Dragonfly::Job::Fetch,
          Dragonfly::Job::Process
        ])
        @job2.temp_object.should be_nil
      end
    end

  end
  
  describe "to_a" do
    before(:each) do
      @app = mock_app
    end
    it "should represent all the steps in array form" do
      job = Dragonfly::Job.new(@app)
      job.fetch! 'some_uid'
      job.generate! :plasma # you wouldn't really call this after fetch but still works
      job.process! :resize, '30x40'
      job.encode! :gif, :bitrate => 20
      job.to_a.should == [
        [:f, 'some_uid'],
        [:g, :plasma],
        [:p, :resize, '30x40'],
        [:e, :gif, {:bitrate => 20}]
      ]
    end
  end
  
  describe "from_a" do
    
    before(:each) do
      @app = mock_app
    end
    
    describe "a well-defined array" do
      before(:each) do
        @job = Dragonfly::Job.from_a([
          [:f, 'some_uid'],
          [:g, :plasma],
          [:p, :resize, '30x40'],
          [:e, :gif, {:bitrate => 20}]
        ], @app)
      end
      it "should have the correct step types" do
        @job.steps.should match_steps([
          Dragonfly::Job::Fetch,
          Dragonfly::Job::Generate,
          Dragonfly::Job::Process,
          Dragonfly::Job::Encode
        ])
      end
      it "should have the correct args" do
        @job.steps[0].args.should == ['some_uid']
        @job.steps[1].args.should == [:plasma]
        @job.steps[2].args.should == [:resize, '30x40']
        @job.steps[3].args.should == [:gif, {:bitrate => 20}]
      end
      it "should have no applied steps" do
        @job.applied_steps.should be_empty
      end
      it "should have all steps pending" do
        @job.steps.should == @job.pending_steps
      end
    end
    
    [
      :f,
      [:f],
      [[]],
      [[:egg]]
    ].each do |object|
      it "should raise an error if the object passed in is #{object.inspect}" do
        lambda {
          Dragonfly::Job.from_a(object, @app)
        }.should raise_error(Dragonfly::Job::InvalidArray)
      end
    end
    
    it "should initialize an empty job if the array is empty" do
      job = Dragonfly::Job.from_a([], @app)
      job.should be_empty
    end
  end
  
  describe "serialization" do
    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app).fetch('mumma').process(:resize, '1x50')
    end
    it "should serialize itself" do
      @job.serialize.should =~ /^\w{1,}$/
    end
    it "should deserialize to the same as the original" do
      new_job = Dragonfly::Job.deserialize(@job.serialize, @app)
      new_job.to_a.should == @job.to_a
    end
  end
  
  describe "to_app" do
    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app)
    end
    it "should return an endpoint" do
      endpoint = @job.to_app
      endpoint.should be_a(Dragonfly::JobEndpoint)
      endpoint.job.should == @job
    end
  end
  
  describe "format" do
    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app)
    end
    it "should return nil if no encoding steps have been defined" do
      @job.format.should be_nil
    end
    it "should return the format of the last encoding step" do
      @job.encode! :gif
      @job.process! :resize, '30x30'
      @job.encode! :png
      @job.process! :resize, '50x50'
      @job.format.should == :png
    end
  end
  
  describe "mime_type" do
    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app)
    end
    it "should return nil if no encoding steps have been defined" do
      @job.mime_type.should be_nil
    end
    it "should get the mime_type of the last encoding step from the app" do
      @job.encode! :png
      @app.should_receive(:mime_type_for).with(:png).and_return 'image/png'
      @job.mime_type.should == 'image/png'
    end
  end
  
end
