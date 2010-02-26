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
      response = make_request(@app, '/hello.png')
      response.status.should == 404
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
      it "should return the fallback mime_type if not known" do
        @app.mime_type_for(:mark).should == 'application/octet-stream'
      end
      it "should return the fallback mime_type if not known" do
        @app.configure{|c| c.fallback_mime_type = 'egg/nog'}
        @app.mime_type_for(:mark).should == 'egg/nog'
      end
      it "should allow for configuring extra mime types" do
        @app.configure{|c| c.register_mime_type 'mark', 'application/mark'}
        @app.mime_type_for(:mark).should == 'application/mark'
      end
      it "should override existing mime types when registered" do
        @app.configure{|c| c.register_mime_type :png, 'ping/pong'}
        @app.mime_type_for(:png).should == 'ping/pong'
      end
    end
    
    describe "Content-Type header" do
      before(:each) do
        Dragonfly::App.send(:apps)[:test] = nil # A Hack to get rspec to reset stuff in between tests
        @app = Dragonfly::App[:test]
        @app.url_handler.protect_from_dos_attacks = false
        @app.datastore = Dragonfly::DataStorage::TransparentDataStore.new
        @app.register_encoder(Dragonfly::Encoding::TransparentEncoder)
        @analyser = Class.new(Dragonfly::Analysis::Base){ def mime_type(*args); 'analyser/mime-type'; end }
      end
      it "should return the fallback mime_type if none registered and no mime_type analyser" do
        make_request(@app, '/some_uid.gog').headers['Content-Type'].should == 'application/octet-stream'
      end
      it "should return the analysed mime-type if an analyser is registered" do
        @app.register_analyser(@analyser)
        make_request(@app, '/some_uid.gog').headers['Content-Type'].should == 'analyser/mime-type'
      end
      it "should return the registered mime_type over the analysed one" do
        @app.register_analyser(@analyser)
        @app.register_mime_type(:gog, 'numb/nut')
        make_request(@app, '/some_uid.gog').headers['Content-Type'].should == 'numb/nut'
      end
      it "should use the fallback mime-type if the registered analyser doesn't respond to 'mime-type'" do
        @app.register_analyser(Class.new(Dragonfly::Analysis::Base))
        make_request(@app, '/some_uid.gog').headers['Content-Type'].should == 'application/octet-stream'
      end
    end
  end

end