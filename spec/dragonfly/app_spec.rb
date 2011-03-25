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
    end
    it "should raise an error if not configured" do
      lambda{
        @app.remote_url_for('some_uid')
      }.should raise_error(NotImplementedError)
    end
    it "should correctly call it if configured" do
      @app.configure do |c|
        c.define_remote_url{|uid| "http://some.cdn/#{uid}" }
      end
      @app.remote_url_for('some_uid').should == 'http://some.cdn/some_uid'
    end
    it "should add any params to the request" do
      @app.define_remote_url{|uid| "http://some.cdn/#{uid}" }
      @app.remote_url_for('some_uid', :some => 'eggs', :and => 'cheese').should == 'http://some.cdn/some_uid?some=eggs&and=cheese'
    end
    it "should correctly add params if it already has some" do
      @app.define_remote_url{|uid| "http://some.cdn/#{uid}?and=bread" }
      @app.remote_url_for('some_uid', :some => 'eggs').should == 'http://some.cdn/some_uid?and=bread&some=eggs'
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
      @app.datastore.should_receive(:store).with(
        a_temp_object_with_data("HELLO"), :meta => {:egg => :head}, :option => :blarney
      )
      @app.store("HELLO", :meta => {:egg => :head}, :option => :blarney)
    end
  end

end
