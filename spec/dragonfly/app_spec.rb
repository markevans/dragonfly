require File.dirname(__FILE__) + '/../spec_helper'
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

  describe "without path prefix or DOS protection" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app).fetch('some_uid')
      @app.datastore.stub!(:retrieve).with('some_uid').and_return "Hi there"
      @app.configure{|c| c.protect_from_dos_attacks = false }
    end
    it "should correctly respond with the job data" do
      response = request(@app, "/#{@job.serialize}")
      response.status.should == 200
      response.body.should == "Hi there"
    end
    it "should generate the correct url" do
      @app.url_for(@job).should == "/#{@job.serialize}"
    end
  end

  describe "path prefix" do
    before(:each) do
      @app = test_app
      @app.configure{|c| c.path_prefix = '/media' }
    end
    it "should return a 404 and X-Cascade if the path prefix doesn't match" do
      response = request(@app, '/abc')
      response.status.should == 404
      response.headers['X-Cascade'].should == 'pass'
    end
    it "should add the path prefix to the url" do
      job = Dragonfly::Job.new(@app)
      @app.url_for(job).should =~ %r{/media/(\w+)}
    end
  end
  
  describe "Denial of Service protection" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app).fetch('some_uid')
    end
    it "should have it on by default" do
      response = request(@app, '/sadhfasdfdsfsdf')
      response.status.should == 400
    end
    it "should generate the correct url" do
      path = "/#{@job.serialize}"
      @app.url_for(@job).should == "#{path}?s=#{Dragonfly::DosProtector.sha_for(path, @app.secret, @app.sha_length)}"
    end
  end

end
