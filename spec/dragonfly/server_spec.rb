require 'spec_helper'
require 'rack/mock'
require 'rack/cache'

def request(app, path)
  Rack::MockRequest.new(app).get(path)
end

describe Dragonfly::Server do

  describe "responses" do
    
    before(:each) do
      @app = test_app
      @uid = @app.store('HELLO THERE')
      @server = Dragonfly::Server.new(@app)
      @server.url_format = '/media/:job'
      @job = @app.fetch(@uid)
    end
  
    after(:each) do
      @app.destroy(@uid)
    end

    describe "successful urls" do
      before(:each) do
        @server.url_format = '/media/:job/:name.:format'
      end

      [
        '',
        '/name',
        '/name.ext'
      ].each do |suffix|

        it "should return the thing when given the url with suffix #{suffix.inspect}" do
          url = "/media/#{@job.serialize}#{suffix}"
          response = request(@server, url)
          response.status.should == 200
          response.body.should == 'HELLO THERE'
          response.content_type.should == 'application/octet-stream'
        end
        
      end
    end

    it "should return a 400 if no sha given but protection on" do
      @server.protect_from_dos_attacks = true
      url = "/media/#{@job.serialize}"
      response = request(@server, url)
      response.status.should == 400
    end
  
    it "should return a 400 if wrong sha given and protection on" do
      @server.protect_from_dos_attacks = true
      url = "/media/#{@job.serialize}?sha=asdfs"
      response = request(@server, url)
      response.status.should == 400
    end

    ['/media', '/media/'].each do |url|
      it "should return a 404 when no job given, e.g. #{url.inspect}" do
        response = request(@server, url)
        response.status.should == 404
        response.body.should == 'Not found'
        response.content_type.should == 'text/plain'
        response.headers['X-Cascade'].should == 'pass'
      end
    end
  
    it "should return a 404 when the url matches but doesn't correspond to a job" do
      response = request(@server, '/media/sadhfasdfdsfsdf')
      response.status.should == 404
      response.body.should == 'Not found'
      response.content_type.should == 'text/plain'
      response.headers['X-Cascade'].should be_nil
    end
  
    it "should return a 404 when the url isn't known at all" do
      response = request(@server, '/jfasd/dsfa')
      response.status.should == 404
      response.body.should == 'Not found'
      response.content_type.should == 'text/plain'
      response.headers['X-Cascade'].should == 'pass'
    end
  
    it "should return a 404 when the url is a well-encoded but bad array" do
      url = "/media/#{Dragonfly::Serializer.marshal_encode([[:egg, {:some => 'args'}]])}"
      response = request(@server, url)
      response.status.should == 404
      response.body.should == 'Not found'
      response.content_type.should == 'text/plain'
      response.headers['X-Cascade'].should be_nil
    end

    # it "should return a simple text response at the root" do
    #   response = request(@server, '/')
    #   response.status.should == 200
    #   response.body.length.should > 0
    #   response.content_type.should == 'text/plain'
    # end

    it "should return a cacheable response" do
      url = "/media/#{@job.serialize}"
      cache = Rack::Cache.new(@server, :entitystore => 'heap:/')
      response = request(cache, url)
      response.status.should == 200
      response.headers['X-Rack-Cache'].should == "miss, store"
      response = request(cache, url)
      response.status.should == 200
      response.headers['X-Rack-Cache'].should == "fresh"
    end

  end
  
  describe "urls" do
    
    before(:each) do
      @app = test_app
      @server = Dragonfly::Server.new(@app)
      @server.url_format = '/media/:job/:basename.:format'
      @job = @app.fetch('some_uid')
      @job.name = nil
      @job.format = nil
    end
    
    it "should generate the correct url when no basename/format" do
      @server.url_for(@job).should == "/media/#{@job.serialize}"
    end
    
    it "should generate the correct url when there is a basename and no format" do
      @job.name = 'hello.png'
      @server.url_for(@job).should == "/media/#{@job.serialize}/hello"
    end
    
    it "should generate the correct url when there is a basename and different format" do
      @job.name = 'hello.png'
      @job.format = :gif
      @server.url_for(@job).should == "/media/#{@job.serialize}/hello.gif"
    end
    
    describe "custom params" do
      before(:each) do
        @server.url_format = '/media/:job/:doobie'
      end

      it "should ignore if not in the meta" do
        @server.url_for(@job).should == "/media/#{@job.serialize}"
      end

      it "should use if in the meta" do
        @job.meta[:doobie] = 'eggs'
        @server.url_for(@job).should == "/media/#{@job.serialize}/eggs"
      end
    end

    describe "url_host" do
      before(:each) do
        @app = test_app
        @server = Dragonfly::Server.new(@app)
        @server.url_format = '/media/:job'
        @job = @app.new_job
      end
      it "should add the host to the url if configured" do
        @server.url_host = 'http://some.server:4000'
        @server.url_for(@job).should =~ %r{^http://some\.server:4000/media/\w+$}
      end
      it "should add the host to the url if passed in" do
        @server.url_for(@job, :host => 'https://bungle.com').should =~ %r{^https://bungle\.com/media/\w+$}
      end
      it "should favour the passed in one" do
        @server.url_host = 'http://some.server:4000'
        @server.url_for(@job, :host => 'https://smeedy').should =~ %r{^https://smeedy/media/\w+$}
      end
    end
  
    describe "url params" do
      before(:each) do
        @app = test_app
        @server = Dragonfly::Server.new(@app)
        @server.url_format = '/media/:job'
        @job = @app.new_job
      end
      it "should add extra params to the url query string" do
        @server.url_for(@job, :a => 'thing', :b => 'nuther').should =~ %r{^/media/\w+\?a=thing&b=nuther$}
      end
    end
  
    describe "Denial of Service protection" do
      before(:each) do
        @app = test_app
        @server = Dragonfly::Server.new(@app)
        @server.protect_from_dos_attacks = true
        @job = @app.new_job.fetch('some_uid')
      end
      it "should generate the correct url" do
        @server.url_for(@job).should == "/media/#{@job.serialize}?sha=#{@job.sha}"
      end
    end

  end
  
end
