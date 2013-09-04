require 'spec_helper'
require 'rack/mock'

def request(app, path)
  Rack::MockRequest.new(app).get(path)
end

describe Dragonfly::App do

  describe ".instance" do

    it "should create a new instance if it didn't already exist" do
      app = Dragonfly::App.instance(:images)
      app.should be_a(Dragonfly::App)
    end

    it "should return an existing instance if called by name" do
      app = Dragonfly::App.instance(:images)
      Dragonfly::App.instance(:images).should == app
    end

    it "should also work using square brackets" do
      Dragonfly[:images].should == Dragonfly::App.instance(:images)
    end

  end

  describe ".new" do
    it "should not be callable" do
      lambda{
        Dragonfly::App.new
      }.should raise_error(NoMethodError)
    end
  end

  describe "default_app" do
    it "returns the default app" do
      Dragonfly::App.default_app.should == Dragonfly::App[:default]
    end
  end

  describe "destroy_apps" do
    it "destroys the dragonfly apps" do
      Dragonfly::App[:gug]
      Dragonfly::App[:blug]
      Dragonfly::App.apps.length.should == 2
      Dragonfly::App.destroy_apps
      Dragonfly::App.apps.length.should == 0
    end
  end

  describe "mime types" do
    describe "#mime_type_for" do
      before(:each) do
        @app = test_app
      end
      it "should return the correct mime type for a symbol" do
        @app.mime_type_for(:png).should == 'image/png'
      end
      it "should work for strings" do
        @app.mime_type_for('png').should == 'image/png'
      end
      it "should work with uppercase strings" do
        @app.mime_type_for('PNG').should == 'image/png'
      end
      it "should work with a dot" do
        @app.mime_type_for('.png').should == 'image/png'
      end
      it "should return the fallback if not known" do
        @app.mime_type_for(:mark).should == 'application/octet-stream'
      end
      it "should allow for configuring extra mime types" do
        @app.add_mime_type 'mark', 'application/mark'
        @app.mime_type_for(:mark).should == 'application/mark'
      end
      it "should override existing mime types when registered" do
        @app.add_mime_type :png, 'ping/pong'
        @app.mime_type_for(:png).should == 'ping/pong'
      end
      it "should have a per-app mime-type configuration" do
        other_app = Dragonfly[:other_app]
        @app.add_mime_type(:mark, 'first/one')
        other_app.add_mime_type(:mark, 'second/one')
        @app.mime_type_for(:mark).should == 'first/one'
        other_app.mime_type_for(:mark).should == 'second/one'
      end
    end
  end

  describe "remote_url_for" do
    before(:each) do
      @app = test_app
      @app.datastore = Object.new
    end
    it "should raise an error if the datastore doesn't provide it" do
      lambda{
        @app.remote_url_for('some_uid')
      }.should raise_error(NotImplementedError)
    end
    it "should correctly call it if the datastore provides it" do
      @app.datastore.should_receive(:url_for).with('some_uid', :some => :opts).and_return 'http://egg.head'
      @app.remote_url_for('some_uid', :some => :opts).should == 'http://egg.head'
    end
  end

  describe "#store" do
    let (:app) { test_app }

    it "should allow just storing content" do
      app.datastore.should_receive(:store).with do |content, opts|
        content.data.should == "HELLO"
      end
      app.store("HELLO")
    end

    it "passes meta and options through too" do
      app.datastore.should_receive(:store).with do |content, opts|
        content.data.should == "HELLO"
        content.meta.should == {'d' => 3}
        opts.should == {:a => :b}
      end
      app.store("HELLO", {'d' => 3}, {:a => :b})
    end
  end

  describe "url_for" do
    let (:app) { test_app }
    let (:job) { app.fetch('eggs') }

    it "should give the server url by default" do
      app.url_for(job).should =~ %r{^/\w+$}
    end
    it "should allow configuring" do
      app.configure do
        define_url do |app, job, opts|
          "doogies"
        end
      end
      app.url_for(job).should == 'doogies'
    end
    it "should yield the correct dooberries" do
      app.define_url do |app, job, opts|
        [app, job, opts]
      end
      app.url_for(job, {'chuddies' => 'margate'}).should == [app, job, {'chuddies' => 'margate'}]
    end
  end

  describe "adding generators" do
    before(:each) do
      @app = test_app.configure do
        generator(:butter){ "BUTTER" }
      end
    end
    it "should return generator methods" do
      @app.generator_methods.should == [:butter]
    end
  end

  describe "adding processors" do
    before(:each) do
      @app = test_app.configure do
        processor(:double){}
      end
    end
    it "should add a method" do
      job1 = @app.create("bunga")
      job2 = job1.double
      job1.should_not == job2
      job1.to_a.should == []
      job2.to_a.should == [['p', :double]]
    end
    it "should add a bang method" do
      job = @app.create("bunga")
      job.double!.should == job
      job.to_a.should == [['p', :double]]
    end
    it "should return processor methods" do
      @app.processor_methods.should == [:double]
    end
  end

  describe "adding analysers" do
    before(:each) do
      @app = test_app.configure do
        add_analyser(:length){|content| content.size }
      end
    end
    it "should add a method" do
      @app.create('123').length.should == 3
    end
    it "should return analyser methods" do
      @app.analyser_methods.should == [:length]
    end
  end

  describe "inspect" do
    it "should give a neat output" do
      Dragonfly[:hello].inspect.should == "<Dragonfly::App name=:hello >"
    end
  end

  describe "configuration" do

    let(:app){ test_app }

    describe "datastore" do
      it "sets the datastore" do
        store = mock('datastore')
        app.configure{ datastore store }
        app.datastore.should == store
      end

      {
        :file => Dragonfly::DataStorage::FileDataStore,
        :s3 => Dragonfly::DataStorage::S3DataStore,
        :couch => Dragonfly::DataStorage::CouchDataStore,
        :mongo => Dragonfly::DataStorage::MongoDataStore,
        :memory => Dragonfly::DataStorage::MemoryDataStore
      }.each do |symbol, klass|
        it "recognises the :s3 shortcut for S3DataStore" do
          app.configure{ datastore symbol }
          app.datastore.should be_a(klass)
        end
      end
    end

    it "raises an error if it doesn't know the symbol" do
      expect{
        app.configure{ datastore :hello }
      }.to raise_error(Dragonfly::App::UnregisteredDataStore)
    end

    it "passes args through to the initializer if a symbol is given" do
      app.configure{ datastore :file, :root_path => '/some/path' }
      app.datastore.root_path.should == '/some/path'
    end

    it "complains if extra args are given but first is not a symbol" do
      store = mock('datastore')
      expect{
        app.configure{ datastore store, :some => 'args' }
      }.to raise_error(ArgumentError)
    end

  end

  describe "define" do
    let(:app){ test_app }

    before :each do
      app.define :exclaim do |n|
        data.upcase + "!"*n
      end
    end

    it "allows defining methods on jobs" do
      app.create("snowman").exclaim(3).should == 'SNOWMAN!!!'
    end
  end

  describe "shell" do
    let(:app){ test_app }

    it "has a shell" do
      app.shell.should be_a(Dragonfly::Shell)
    end
  end

  describe "env" do
    let(:app){ test_app }

    it "stores environment variables" do
      app.env.should == {}
      app.env[:doogie] = 'blisto'
      app.env[:doogie].should == 'blisto'
    end
  end

end

