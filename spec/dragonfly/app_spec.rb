require File.dirname(__FILE__) + '/../spec_helper'
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
    
    it "should also work using square brackets" do
      Dragonfly::App[:images].should == Dragonfly::App.instance(:images)
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
        Dragonfly::App.send(:apps)[:images] = nil # A Hack to get rspec to reset stuff in between tests
        @app = Dragonfly::App[:images]
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
        other_app = Dragonfly::App[:other_app]
        @app.register_mime_type(:mark, 'first/one')
        other_app.register_mime_type(:mark, 'second/one')
        @app.mime_type_for(:mark).should == 'first/one'
        other_app.mime_type_for(:mark).should == 'second/one'
      end
    end
  end

  describe "simple integration tests" do

    def request(app, path)
      Rack::MockRequest.new(app).get(path)
    end

    before(:each) do
      @app = Dragonfly::App[:simple_integration_tests]
      @app.log = Logger.new($stderr)
      @uid = @app.store('HELLO THERE')
    end
    
    after(:each) do
      @app.destroy(@uid)
    end
    
    it "should get the stored thing" do
      @app.fetch(@uid).data.should == 'HELLO THERE'
    end
    
    it "should return the thing when given the url" do
      url = @app.fetch(@uid).url
      response = request(@app, url)
      response.status.should == 200
      response.body.should == 'HELLO THERE'
      response.content_type.should == 'application/octet-stream'
    end
    
    it "should return a 404 when the url isn't known" do
      response = request(@app, '/sadhfasdfdsfsdf')
      response.status.should == 404
      response.body.should == 'Not found'
      response.content_type.should == 'text/plain'
    end
    
    it "should return a 404 when the url is a well-encoded but bad array" do
      url = "/#{Dragonfly::Serializer.marshal_encode([[:egg, {:some => 'args'}]])}"
      response = request(@app, url)
      response.status.should == 404
      response.body.should == 'Not found'
      response.content_type.should == 'text/plain'
    end
  end

end
