# encoding: UTF-8
require 'spec_helper'

describe Dragonfly::Job do

  describe "Step types" do

    {
      Dragonfly::Job::Fetch => :fetch,
      Dragonfly::Job::Process => :process,
      Dragonfly::Job::Generate => :generate,
      Dragonfly::Job::FetchFile => :fetch_file,
      Dragonfly::Job::FetchUrl => :fetch_url
    }.each do |klass, step_name|
      it "should return the correct step name for #{klass}" do
        klass.step_name.should == step_name
      end
    end

    {
      Dragonfly::Job::Fetch => 'f',
      Dragonfly::Job::Process => 'p',
      Dragonfly::Job::Generate => 'g',
      Dragonfly::Job::FetchFile => 'ff',
      Dragonfly::Job::FetchUrl => 'fu'
    }.each do |klass, abbreviation|
      it "should return the correct abbreviation for #{klass}" do
        klass.abbreviation.should == abbreviation
      end
    end

    describe "step_names" do
      it "should return the available step names" do
        Dragonfly::Job.step_names.should == [:fetch, :process, :generate, :fetch_file, :fetch_url]
      end
    end

  end

  let (:app) { test_app }
  let (:job) { Dragonfly::Job.new(app) }

  it "allows initializing with content" do
    job = Dragonfly::Job.new(app, 'eggheads')
    job.data.should == 'eggheads'
  end

  describe "content" do
    it "starts with an empty content" do
      job.content.should be_a(Dragonfly::Content)
      job.content.data.should == ""
      job.content.meta.should == {}
    end
  end

  describe "apply" do
    it "should return itself" do
      job.apply.should == job
    end
  end

  describe "analysis" do
    let (:job) { Dragonfly::Job.new(app, "HELLO") }

    before(:each) do
      app.add_analyser(:num_ls){|content| content.data.count('L') }
    end
    it "should return correctly when calling analyse" do
      job.analyse(:num_ls).should == 2
    end
    it "should work correctly with chained jobs, applying before analysing" do
      app.add_processor(:double){|content| content.update(content.data * 2) }
      job.process(:double).analyse(:num_ls).should == 4
    end
  end

  describe "defining extra steps after applying" do
    before(:each) do
      @app = test_app
      @app.add_processor(:resize){}
      @app.add_processor(:encode){}
      @job = Dragonfly::Job.new(@app)
      @job.process! :resize
      @job.apply
      @job.process! :encode
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
      @job.steps.map{|step| step.name }.should == [:resize, :encode]
    end
    it "should return applied steps" do
      @job.applied_steps.map{|step| step.name }.should == [:resize]
    end
    it "should return the pending steps" do
      @job.pending_steps.map{|step| step.name }.should == [:encode]
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
      @app = test_app
      @job = Dragonfly::Job.new(@app)
      @app.add_processor(:resize){|content, length| content.update(content.data[0...length]) }
      @app.store("SOME_DATA", {}, :uid => 'some_uid')
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
        @job2 = @job.process(:resize, 4)
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
        @job2.data.should == 'SOME'
      end
    end

  end

  describe "applied?" do
    it "should return true when empty" do
      app.new_job.should be_applied
    end
    it "should return false when not applied" do
      app.fetch('eggs').should_not be_applied
    end
    it "should return true when applied" do
      job = app.fetch('eggs')
      app.datastore.should_receive(:read).with('eggs').and_return ["", {}]
      job.apply
      job.should be_applied
    end
  end

  describe "to_a" do
    before(:each) do
      @app = test_app
      @app.add_generator(:plasma){}
      @app.add_processor(:resize){}
    end
    it "should represent all the steps in array form" do
      job = Dragonfly::Job.new(@app)
      job.fetch! 'some_uid'
      job.generate! :plasma # you wouldn't really call this after fetch but still works
      job.process! :resize, '30x40'
      job.to_a.should == [
        ['f', 'some_uid'],
        ['g', :plasma],
        ['p', :resize, '30x40']
      ]
    end
  end

  describe "from_a" do

    before(:each) do
      @app = test_app
      @app.add_generator(:plasma){}
      @app.add_processor(:resize){}
    end

    describe "a well-defined array" do
      before(:each) do
        @job = Dragonfly::Job.from_a([
          ['f', 'some_uid'],
          ['g', 'plasma'],
          ['p', 'resize', '30x40']
        ], @app)
      end
      it "should have the correct step types" do
        @job.steps.should match_steps([
          Dragonfly::Job::Fetch,
          Dragonfly::Job::Generate,
          Dragonfly::Job::Process,
        ])
      end
      it "should have the correct args" do
        @job.steps[0].args.should == ['some_uid']
        @job.steps[1].args.should == ['plasma']
        @job.steps[2].args.should == ['resize', '30x40']
      end
      it "should have no applied steps" do
        @job.applied_steps.should be_empty
      end
      it "should have all steps pending" do
        @job.steps.should == @job.pending_steps
      end
    end

    it "works with symbols" do
      job = Dragonfly::Job.from_a([[:f, 'some_uid']], @app)
      job.steps.should match_steps([Dragonfly::Job::Fetch])
    end

    [
      'f',
      ['f'],
      [[]],
      [['egg']]
    ].each do |object|
      it "should raise an error if the object passed in is #{object.inspect}" do
        lambda {
          Dragonfly::Job.from_a(object, @app)
        }.should raise_error(Dragonfly::Job::InvalidArray)
      end
    end

    it "should initialize an empty job if the array is empty" do
      job = Dragonfly::Job.from_a([], @app)
      job.steps.should be_empty
    end
  end

  describe "serialization" do
    before(:each) do
      @app = test_app
      @app.add_processor(:resize_and_crop){}
      @job = Dragonfly::Job.new(@app).fetch('uid').process(:resize_and_crop, 'width' => 270, 'height' => 92, 'gravity' => 'n')
    end
    it "should serialize itself" do
      @job.serialize.should =~ /^\w{1,}$/
    end
    it "should deserialize to the same as the original" do
      new_job = Dragonfly::Job.deserialize(@job.serialize, @app)

      new_job.steps.length.should == 2
      fetch_step, process_step = new_job.steps

      fetch_step.should be_a(Dragonfly::Job::Fetch)
      fetch_step.uid.should == 'uid'

      process_step.should be_a(Dragonfly::Job::Process)
      process_step.name.should == :resize_and_crop
      process_step.arguments.should == [{'width' => 270, 'height' => 92, 'gravity' => 'n'}]
    end
    it "works with json encoded strings" do
      job = Dragonfly::Job.deserialize("W1siZiIsInNvbWVfdWlkIl1d", @app)
      job.fetch_step.uid.should == 'some_uid'
    end

    context 'legacy urls are enabled' do
      before do
        @app.allow_legacy_urls = true
      end

      it "works with marshal encoded strings (deprecated)" do
        job = Dragonfly::Job.deserialize("BAhbBlsHSSIGZgY6BkVUSSINc29tZV91aWQGOwBU", @app)
        job.fetch_step.uid.should == 'some_uid'
      end

      it "checks for potentially malicious strings" do
        string = Base64.encode64(Marshal.dump(Dragonfly::TempObject.new('a'))).tr("\n=",'')
        expect{
          Dragonfly::Job.deserialize(string, @app)
        }.to raise_error(Dragonfly::Serializer::MaliciousString)
      end
    end

    context 'legacy urls are disabled (default)' do
      it "rejects marshal encoded strings " do
        expect {Dragonfly::Job.deserialize("BAhbBlsHSSIGZgY6BkVUSSINc29tZV91aWQGOwBU", @app)}.to raise_error(Dragonfly::Serializer::BadString)
      end
    end
  end

  describe "to_app" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app)
    end
    it "should return an endpoint" do
      endpoint = @job.to_app
      endpoint.should be_a(Dragonfly::JobEndpoint)
      endpoint.job.should == @job
    end
  end

  describe "update_url_attributes" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(:app)
      @job.url_attributes.hello = 'goose'
    end
    it "updates the url_attributes" do
      @job.update_url_attributes(:jimmy => 'cricket')
      @job.url_attributes.hello.should == 'goose'
      @job.url_attributes.jimmy.should == 'cricket'
    end
    it "overrides keys" do
      @job.update_url_attributes(:hello => 'cricket')
      @job.url_attributes.hello.should == 'cricket'
    end
  end

  describe "url_attributes" do
    it "doesn't interfere with other jobs' attributes" do
      job.url_attributes.zoo = 'hair'
      job2 = job.dup
      job2.url_attributes.zoo = 'dare'

      job.url_attributes.zoo.should == 'hair'
      job2.url_attributes.zoo.should == 'dare'
    end
  end

  describe "url" do
    let (:app) { test_app }
    let (:job) { Dragonfly::Job.new(app) }

    it "returns nil if there are no steps" do
      job.url.should be_nil
    end

    it "uses the server url otherwise" do
      job.fetch!("some_stuff")
      opts = {:some => "opts"}
      app.server.should_receive(:url_for).with(job, opts).and_return("some.url")
      job.url(opts).should == "some.url"
    end
  end

  describe "to_fetched_job" do
    let (:fetched_job) { job.to_fetched_job('some_uid') }

    before :each do
      job.content.update "bugs", "bug" => "bear"
      job.update_url_attributes "boog" => "bar"
    end

    it "updates the steps" do
      fetched_job.to_a.should == [
        ['f', 'some_uid']
      ]
      fetched_job.should be_applied
    end
    it "maintains the same content (but different object)" do
      fetched_job.data.should == "bugs"
      fetched_job.meta.should == {"bug" => "bear"}
      job.content.update("dogs")
      fetched_job.data.should == "bugs" # still
    end
    it "maintains the url_attributes (but different object)" do
      fetched_job.url_attributes.boog.should == "bar"
      job.update_url_attributes "boog" => "dogs"
      fetched_job.url_attributes.boog.should == "bar" # still
    end
  end

  describe "to_unique_s" do
    it "should use the arrays of args to create the string" do
      app = test_app
      app.add_processor(:gug){}
      job = app.fetch('uid').process(:gug, 4, 'some' => 'arg', 'and' => 'more')
      job.to_unique_s.should == 'fuidpgug4andmoresomearg'
    end
  end

  describe "sha" do
    before(:each) do
      @app = test_app
      @job = @app.fetch('eggs')
    end

    it "should be of the correct format" do
      @job.sha.should =~ /^\w{16}$/
    end

    it "should be the same for the same job steps" do
      @app.fetch('eggs').sha.should == @job.sha
    end

    it "should be different for different jobs" do
      @app.fetch('figs').sha.should_not == @job.sha
    end

    it "should raise error when secret is unspecified" do
      @app.secret = nil
      expect{ @app.fetch('figs').sha }.to raise_error(Dragonfly::Job::CannotGenerateSha)
    end
  end

  describe "validate_sha!" do
    before(:each) do
      @app = test_app
      @job = @app.fetch('eggs')
    end
    it "should raise an error if nothing is given" do
      lambda{
        @job.validate_sha!(nil)
      }.should raise_error(Dragonfly::Job::NoSHAGiven)
    end
    it "should raise an error if the wrong SHA is given" do
      lambda{
        @job.validate_sha!('asdf')
      }.should raise_error(Dragonfly::Job::IncorrectSHA)
    end
    it "should return self if ok" do
      @job.validate_sha!(@job.sha).should == @job
    end
  end

  describe "b64_data" do
    it "takes it from the result" do
      job.should_receive(:apply)
      job.b64_data.should =~ /^data:/
    end
  end

  describe "querying stuff without applying steps" do
    before(:each) do
      @app = test_app
      @app.add_generator(:ponies){}
      @app.add_processor(:jam){}
    end

    describe "fetch_step" do
      it "should return nil if it doesn't exist" do
        @app.generate(:ponies).process(:jam).fetch_step.should be_nil
      end
      it "should return the fetch step otherwise" do
        step = @app.fetch('hello').process(:jam).fetch_step
        step.should be_a(Dragonfly::Job::Fetch)
        step.uid.should == 'hello'
      end
    end
    describe "uid" do
      describe "when there's no fetch step" do
        before(:each) do
          @job = @app.new_job("AGG")
        end
        it "should return nil for uid" do
          @job.uid.should be_nil
        end
      end
      describe "when there is a fetch step" do
        before(:each) do
          @job = @app.fetch('gungedin/innit.blud')
        end
        it "should return the uid" do
          @job.uid.should == 'gungedin/innit.blud'
        end
      end
    end

    describe "fetch_file_step" do
      it "should return nil if it doesn't exist" do
        @app.generate(:ponies).process(:jam).fetch_file_step.should be_nil
      end
      it "should return the fetch_file step otherwise" do
        step = @app.fetch_file('/my/file.png').process(:jam).fetch_file_step
        step.should be_a(Dragonfly::Job::FetchFile)
        if Dragonfly.running_on_windows?
          step.path.should =~ %r(:/my/file\.png$)
        else
          step.path.should == '/my/file.png'
        end
      end
      it "converts pathname to a string in to_a" do
        job = @app.fetch_file(Pathname.new('some/where'))
        job.to_a.should == [['ff', 'some/where']]
      end
    end

    describe "fetch_url_step" do
      it "should return nil if it doesn't exist" do
        @app.generate(:ponies).fetch_url_step.should be_nil
      end
      it "should return the fetch_url step otherwise" do
        step = @app.fetch_url('egg.heads').process(:jam).fetch_url_step
        step.should be_a(Dragonfly::Job::FetchUrl)
        step.url.should == 'http://egg.heads'
      end
    end

    describe "generate_step" do
      it "should return nil if it doesn't exist" do
        @app.fetch('many/ponies').process(:jam).generate_step.should be_nil
      end
      it "should return the generate step otherwise" do
        step = @app.generate(:ponies).process(:jam).generate_step
        step.should be_a(Dragonfly::Job::Generate)
        step.name.should == :ponies
      end
    end

    describe "process_steps" do
      it "should return the processing steps" do
        @app.add_processor(:eggs){}
        job = @app.fetch('many/ponies').process(:jam).process(:eggs)
        job.process_steps.should match_steps([
          Dragonfly::Job::Process,
          Dragonfly::Job::Process
        ])
      end
    end

    describe "step_types" do
      it "should return the step types" do
        job = @app.fetch('eggs').process(:jam)
        job.step_types.should == [:fetch, :process]
      end
    end
  end

  describe "meta" do
    it "delegates to the result" do
      job.should_receive(:apply)
      job.meta = {'a' => 'b'}
      job.should_receive(:apply)
      job.meta.should == {'a' => 'b'}
    end
  end

  describe "sanity check for name, basename, ext, mime_type" do
    it "should default to nil" do
      job.name.should be_nil
    end

    it "reflect the meta" do
      job.meta['name'] = 'monkey.png'
      job.name.should == 'monkey.png'
      job.basename.should == 'monkey'
      job.ext.should == 'png'
      job.mime_type.should == 'image/png'
    end
  end

  describe "store" do
    it "calls store on the applied content" do
      job.should_receive(:apply)
      app.datastore.should_receive(:write).with(job.content, {})
      job.store
    end
  end

end

