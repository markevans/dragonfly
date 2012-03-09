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
      it "should return nil if not known" do
        @app.mime_type_for(:mark).should be_nil
      end
      it "should allow for configuring extra mime types" do
        @app.register_mime_type 'mark', 'application/mark'
        @app.mime_type_for(:mark).should == 'application/mark'
      end
      it "should override existing mime types when registered" do
        @app.register_mime_type :png, 'ping/pong'
        @app.mime_type_for(:png).should == 'ping/pong'
      end
      it "should have a per-app mime-type configuration" do
        other_app = Dragonfly[:other_app]
        @app.register_mime_type(:mark, 'first/one')
        other_app.register_mime_type(:mark, 'second/one')
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
    before(:each) do
      @app = test_app
    end
    it "should allow just storing content" do
      @app.datastore.should_receive(:store).with(a_temp_object_with_data("HELLO"), {})
      @app.store("HELLO")
    end
    it "should allow storing using a TempObject" do
      temp_object = Dragonfly::TempObject.new("HELLO")
      @app.datastore.should_receive(:store).with(temp_object, {})
      @app.store(temp_object)
    end
    it "should allow storing with extra stuff" do
      @app.datastore.should_receive(:store).with do |temp_object, opts|
        temp_object.data.should == 'HELLO'
        temp_object.meta.should == {:egg => :head}
        opts[:option].should == :blarney
      end
      @app.store("HELLO", :meta => {:egg => :head}, :option => :blarney)
    end
    it "should still pass in meta in the opts arg, for deprecated use of meta" do
      @app.datastore.should_receive(:store).with do |temp_object, opts|
        opts[:meta].should == {:egg => :head}
      end
      @app.store("HELLO", :meta => {:egg => :head}, :option => :blarney)
    end
  end

  describe "url_for" do
    before(:each) do
      @app = test_app
      @job = @app.fetch('eggs')
    end
    it "should give the server url by default" do
      @app.url_for(@job).should =~ %r{^/\w+$}
    end
    it "should allow configuring" do
      @app.configure do |c|
        c.define_url do |app, job, opts|
          "doogies"
        end
      end
      @app.url_for(@job).should == 'doogies'
    end
    it "should yield the correct dooberries" do
      @app.define_url do |app, job, opts|
        [app, job, opts]
      end
      @app.url_for(@job, {'chuddies' => 'margate'}).should == [@app, @job, {'chuddies' => 'margate'}]
    end
  end

  describe "reflection methods" do
    before(:each) do
      @app = test_app.configure do |c|
        c.processor.add(:milk){}
        c.generator.add(:butter){}
        c.analyser.add(:cheese){}
        c.job(:bacon){}
      end
      
    end
    it "should return processor methods" do
      @app.processor_methods.should == [:milk]
    end
    it "should return generator methods" do
      @app.generator_methods.should == [:butter]
    end
    it "should return analyser methods" do
      @app.analyser_methods.should == [:cheese]
    end
    it "should return job methods" do
      @app.job_methods.should == [:bacon]
    end
  end

  describe "inspect" do
    it "should give a neat output" do
      Dragonfly[:hello].inspect.should == "<Dragonfly::App name=:hello >"
    end
  end

end
