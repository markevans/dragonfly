require 'spec_helper'
require 'rack/mock'

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

    it "has a default instance" do
      Dragonfly::App.instance.should be_a(Dragonfly::App)
    end

    it "returns the default instance if passed nil" do
      Dragonfly::App.instance(nil).should == Dragonfly::App.instance
    end

  end

  describe ".new" do
    it "should not be callable" do
      lambda{
        Dragonfly::App.new
      }.should raise_error(NoMethodError)
    end
  end

  describe "destroy_apps" do
    it "destroys the dragonfly apps" do
      Dragonfly::App.instance(:gug)
      Dragonfly::App.instance(:blug)
      Dragonfly::App.apps.length.should == 2
      Dragonfly::App.destroy_apps
      Dragonfly::App.apps.length.should == 0
    end
  end

  describe "mime types" do
    let(:app) { test_app }

    describe "#mime_type_for" do
      it "should return the correct mime type for a symbol" do
        app.mime_type_for(:png).should == 'image/png'
      end
      it "should work for strings" do
        app.mime_type_for('png').should == 'image/png'
      end
      it "should work with uppercase strings" do
        app.mime_type_for('PNG').should == 'image/png'
      end
      it "should work with a dot" do
        app.mime_type_for('.png').should == 'image/png'
      end
      it "should return the fallback if not known" do
        app.mime_type_for(:mark).should == 'application/octet-stream'
      end
      it "should allow for configuring extra mime types" do
        app.add_mime_type 'mark', 'application/mark'
        app.mime_type_for(:mark).should == 'application/mark'
      end
      it "should override existing mime types when registered" do
        app.add_mime_type :png, 'ping/pong'
        app.mime_type_for(:png).should == 'ping/pong'
      end
      it "should have a per-app mime-type configuration" do
        other_app = Dragonfly.app(:other_app)
        app.add_mime_type(:mark, 'first/one')
        other_app.add_mime_type(:mark, 'second/one')
        app.mime_type_for(:mark).should == 'first/one'
        other_app.mime_type_for(:mark).should == 'second/one'
      end
      it "can be added via configure" do
        app.configure{ mime_type 'mark', 'application/mark' }
        app.mime_type_for(:mark).should == 'application/mark'
      end
    end

    describe "#ext_for" do
      it "returns the ext corresponding to a mime_type" do
        app.ext_for('image/png').should == 'png'
      end

      it "returns nil if non-existent" do
        app.ext_for('big/bum').should be_nil
      end

      it "returns txt for text/plain" do
        app.ext_for('text/plain').should == 'txt'
      end
    end
  end

  describe "create" do
    let (:app) { test_app }

    it "creates a new job with the specified data/meta" do
      job = app.create("hello", 'a' => 'b')
      job.should be_a(Dragonfly::Job)
      job.data.should == 'hello'
      job.meta['a'].should == 'b'
    end

    it "accepts other jobs" do
      job2 = app.create("other", 'c' => 'd')
      job = app.create(job2)
      job.data.should == 'other'
      job.meta['c'].should == 'd'
    end

    it "accepts Attachments" do
      Car = new_model_class('Car', :make_uid) do
        dragonfly_accessor :make
      end
      car = Car.new(:make => 'jaguar')
      car.make.meta['a'] = 'b'
      job = app.create(car.make)
      job.data.should == 'jaguar'
      job.meta['a'].should == 'b'
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
      app.datastore.should_receive(:write).with(
        satisfy{|content| content.data == 'HELLO'},
        anything
      )
      app.store("HELLO")
    end

    it "passes meta and options through too" do
      app.datastore.should_receive(:write).with(
        satisfy{|content| content.data == 'HELLO' && content.meta == {'d' => 3} },
        {a: :b}
      )
      app.store("HELLO", {'d' => 3}, {:a => :b})
    end
  end

  describe "url_for" do
    let (:app) { test_app }
    let (:job) { app.fetch('eggs') }

    it "should give the server url by default" do
      app.url_for(job).should =~ %r{^/\w+}
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
        analyser(:length){|content| content.size }
      end
    end
    it "should add a method" do
      @app.create('123').length.should == 3
    end
    it "should return analyser methods" do
      @app.analyser_methods.should == [:length]
    end
  end

  describe "response headers" do
    let (:app) {test_app}

    it "adds a response header" do
      app.response_header 'Cache-Control', "private"
      app.response_headers["Cache-Control"].should == 'private'
    end

    it "adds a response header using a block" do
      app.response_header 'Cache-Control' do "private" end
      app.response_headers["Cache-Control"].should be_a(Proc)
    end

    it "allows calling through the config" do
      app.configure{ response_header 'Cache-Control', "private" }
    end
  end

  describe "inspect" do
    it "should give a neat output" do
      Dragonfly.app(:hello).inspect.should == "<Dragonfly::App name=:hello >"
    end
  end

  describe "configuration" do

    let(:app){ test_app }

    describe "datastore" do
      it "sets the datastore" do
        store = double('datastore')
        app.configure{ datastore store }
        app.datastore.should == store
      end

      {
        :file => Dragonfly::FileDataStore,
        :memory => Dragonfly::MemoryDataStore
      }.each do |symbol, klass|
        it "recognises the #{symbol.inspect} shortcut for S3DataStore" do
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
      store = double('datastore')
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

    it "can be added through configure" do
      app.configure{ define(:googie){} }
      app.create("snowman").googie.should be_nil
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

  describe "deprecations" do
    it "raises a message when using App#[]" do
      expect {
        Dragonfly::App[:images]
      }.to raise_error(/Dragonfly::App\[:images\] .* Dragonfly\.app /)
    end

    it "raises a message when configuring with an old datastore" do
      expect {
        Dragonfly.app.use_datastore(double("datastore", :store => "asdf", :retrieve => "ASDF", :destroy => nil))
      }.to raise_error(/read/)
    end

    it "raises a messages when configuring with a bad parameter" do
      expect {
        Dragonfly.app.configure do |c|
          c.url_format = '/media/:job'
        end
      }.to raise_error(/no method.*changed.*docs/)
    end

    it "raises a message when calling App#define_macro" do
      expect {
        Dragonfly.app.define_macro(Object, :image_accessor)
      }.to raise_error(/dragonfly_accessor/)
    end

    it "raises a message when calling App#define_macro_on_include" do
      expect {
        Dragonfly.app.define_macro_on_include(Module.new, :image_accessor)
      }.to raise_error(/dragonfly_accessor/)
    end
  end

end

