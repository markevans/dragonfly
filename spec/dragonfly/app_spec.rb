require File.dirname(__FILE__) + '/../spec_helper'
require 'rack/mock'

describe Dragonfly::App do

  def make_request(app, url)
    Rack::MockRequest.new(app).get(url)
  end

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
  
  describe "errors" do

    before(:each) do
      @app = Dragonfly::App[:images]
    end

    it "should return 400 if UrlHandler::IncorrectSHA is raised" do
      @app.url_handler.should_receive(:url_to_parameters).and_raise(Dragonfly::UrlHandler::IncorrectSHA)
      response = make_request(@app, '/some_uid.png?s=sadfas')
      response.status.should == 400
    end
    
    it "should return 400 if UrlHandler::SHANotGiven is raised" do
      @app.url_handler.should_receive(:url_to_parameters).and_raise(Dragonfly::UrlHandler::SHANotGiven)
      response = make_request(@app, '/some_uid.png?s=asdfghsg')
      response.status.should == 400
    end
    
    it "should return 404 if url handler raises an unknown url exception" do
      @app.url_handler.should_receive(:url_to_parameters).and_raise(Dragonfly::UrlHandler::UnknownUrl)
      response = make_request(@app, '/')
      response.status.should == 404
    end

    it "should return 404 if the datastore raises data not found" do
      @app.url_handler.protect_from_dos_attacks = false
      @app.should_receive(:fetch).and_raise(Dragonfly::DataStorage::DataNotFound)
      response = make_request(@app, 'hello.png')
      response.status.should == 404
    end

  end

  describe "mime types" do
    before(:each) do
      @app = Dragonfly::App[:images]
      @app.url_handler.protect_from_dos_attacks = false
      @app.fallback_mime_type = 'egg/heads'
      @temp_object = Dragonfly::TempObject.new('GOOG')
      @app.stub!(:fetch).and_return(@temp_object)
    end
    it "should use the temp object mime-type" do
      @temp_object.should_receive(:mime_type).and_return 'my/type'
      response = make_request(@app, 'hello.png')
      response.headers['Content-Type'].should == 'my/type'
    end
    it "should use the app's fallback mime-type if the temp_object one isn't known" do
      @temp_object.should_receive(:mime_type).and_return nil
      response = make_request(@app, 'hello.png')
      response.headers['Content-Type'].should == 'egg/heads'
    end
  end

end