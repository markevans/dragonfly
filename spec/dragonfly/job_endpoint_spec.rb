# encoding: utf-8
require 'spec_helper'

## General tests for Response go here as it's a pretty simple wrapper around that

describe "Dragonfly::JobEndpoint Rack::Lint tests" do
  before(:each) do
    @app = test_app
    @app.generator.add(:test_data){ "Test Data" }
    @job = @app.generate(:test_data)
    @endpoint = Rack::Lint.new(Dragonfly::JobEndpoint.new(@job))
  end
  
  it "should pass for HEAD requests" do
    Rack::MockRequest.new(@endpoint).request("HEAD", '')
  end
  
  it "should pass for GET requests" do
    Rack::MockRequest.new(@endpoint).request("GET", '')
  end
  
  it "should pass for POST requests" do
    Rack::MockRequest.new(@endpoint).request("POST", '')
  end
  
  it "should pass for PUT requests" do
    Rack::MockRequest.new(@endpoint).request("PUT", '')
  end
  
  it "should pass for DELETE requests" do
    Rack::MockRequest.new(@endpoint).request("DELETE", '')
  end
end

describe Dragonfly::JobEndpoint do

  def make_request(job, opts={})
    endpoint = Dragonfly::JobEndpoint.new(job)
    method = (opts.delete(:method) || :get).to_s.upcase
    Rack::MockRequest.new(endpoint).request(method, '', opts)
  end

  before(:each) do
    @app = test_app
    @app.datastore.stub!(:retrieve).with('egg').and_return(["GUNGLE", {:name => 'gung.txt'}])
    @job = @app.new_job.fetch('egg')
  end

  it "should return a correct response to a successful GET request" do
    response = make_request(@job)
    response.status.should == 200
    response['ETag'].should =~ /^"\w+"$/
    response['Cache-Control'].should == "public, max-age=31536000"
    response['Content-Type'].should == 'text/plain'
    response['Content-Length'].should == '6'
    response['Content-Disposition'].should == 'filename="gung.txt"'
    response.body.should == 'GUNGLE'
  end

  it "should return the correct headers and no content to a successful HEAD request" do
    response = make_request(@job, :method => :head)
    response.status.should == 200
    response['ETag'].should =~ /^"\w+"$/
    response['Cache-Control'].should == "public, max-age=31536000"
    response['Content-Type'].should == 'text/plain'
    response['Content-Length'].should == '6'
    response['Content-Disposition'].should == 'filename="gung.txt"'
    response.body.should == ''
  end

  %w(POST PUT DELETE CUSTOM_METHOD).each do |method|
    
    it "should return a 405 error for a #{method} request" do
      response = make_request(@job, :method => method)
      response.status.should == 405
      response['Allow'].should == "GET, HEAD"
      response['Content-Type'].should == 'text/plain'
      response.body.should == "#{method} method not allowed"
    end

  end

  it "should return 404 if the datastore raises data not found" do
    @job.should_receive(:apply).and_raise(Dragonfly::DataStorage::DataNotFound)
    response = make_request(@job)
    response.status.should == 404
  end

  it "should return a 404 if the datastore raises bad uid" do
    @job.should_receive(:apply).and_raise(Dragonfly::DataStorage::BadUID)
    response = make_request(@job)
    response.status.should == 404
  end

  describe "ETag" do
    it "should return an ETag" do
      response = make_request(@job)
      response.headers['ETag'].should =~ /^"\w+"$/
    end

    [
      "dingle",
      "dingle, eggheads",
      '"dingle", "eggheads"',
      '*'
    ].each do |header|
      it "should return a 304 if the correct ETag is specified in HTTP_IF_NONE_MATCH header e.g. #{header}" do
        @job.should_receive(:unique_signature).at_least(:once).and_return('dingle')
        response = make_request(@job, 'HTTP_IF_NONE_MATCH' => header)
        response.status.should == 304
        response['ETag'].should == '"dingle"'
        response['Cache-Control'].should == "public, max-age=31536000"
        response.body.should be_empty
      end
    end

    it "should not have applied any steps if the correct ETag is specified in HTTP_IF_NONE_MATCH header" do
      response = make_request(@job, 'HTTP_IF_NONE_MATCH' => @job.unique_signature)
      @job.applied_steps.should be_empty
    end
  end

  describe "Content Disposition" do
    before(:each) do
      @app.encoder.add{|temp_object, format| temp_object }
    end

    describe "filename" do
      it "should return the original name" do
        response = make_request(@job)
        response['Content-Disposition'].should == 'filename="gung.txt"'
      end
      it "should return a filename with a different extension if it's been encoded" do
        response = make_request(@job.encode(:doogs))
        response['Content-Disposition'].should == 'filename="gung.doogs"'
      end
      it "should not have the filename if name doesn't exist" do
        response = make_request(@app.new_job("ADFSDF"))
        response['Content-Disposition'].should be_nil
      end
      it "should cope with filenames with no ext" do
        response = make_request(@app.new_job("ASDF", :name => 'asdf'))
        response['Content-Disposition'].should == 'filename="asdf"'
      end
      it "should uri encode funny characters" do
        response = make_request(@app.new_job("ASDF", :name => '£@$£ `'))
        response['Content-Disposition'].should == 'filename="%C2%A3@$%C2%A3%20%60"'
      end
      it "should allow for setting the filename using a block" do
        @app.content_filename = proc{|job, request|
          job.basename.reverse.upcase + request['a']
        }
        response = make_request(@job, 'QUERY_STRING' => 'a=egg')
        response['Content-Disposition'].should == 'filename="GNUGegg"'
      end
      it "should not include the filename if configured to be nil" do
        @app.content_filename = nil
        response = make_request(@job)
        response['Content-Disposition'].should be_nil
      end
    end

    describe "content disposition" do
      it "should use the app's configured content-disposition" do
        @app.content_disposition = :attachment
        response = make_request(@job)
        response['Content-Disposition'].should == 'attachment; filename="gung.txt"'
      end
      it "should allow using a block to set the content disposition" do
        @app.content_disposition = proc{|job, request|
          job.basename + request['blah']
        }
        response = make_request(@job, 'QUERY_STRING' => 'blah=yo')
        response['Content-Disposition'].should == 'gungyo; filename="gung.txt"'
      end
    end
  end
  
  describe "custom headers" do
    before(:each) do
      @app.configure{|c| c.response_headers['This-is'] = 'brill' }
    end
    it "should allow specifying custom headers" do
      make_request(@job).headers['This-is'].should == 'brill'
    end
    it "should not interfere with other headers" do
      make_request(@job).headers['Content-Length'].should == '6'
    end
    it "should allow overridding other headers" do
      @app.response_headers['Cache-Control'] = 'try me'
      make_request(@job).headers['Cache-Control'].should == 'try me'
    end
    it "should allow giving a proc" do
      @app.response_headers['Cache-Control'] = proc{|job, request|
        job.basename.reverse.upcase + request['a']
      }
      response = make_request(@job, 'QUERY_STRING' => 'a=egg')
      response['Cache-Control'].should == 'GNUGegg'
    end
  end

  describe "setting the job in the env for communicating with other rack middlewares" do
    before(:each) do
      @app.generator.add(:test_data){ "TEST DATA" }
      @job = @app.generate(:test_data)
      @endpoint = Dragonfly::JobEndpoint.new(@job)
      @middleware = Class.new do
        def initialize(app)
          @app = app
        end
        
        def call(env)
          @app.call(env)
          throw :result, env['dragonfly.job']
        end
      end
    end
    it "should add the job to env" do
      middleware, endpoint = @middleware, @endpoint
      app = Rack::Builder.new do
        use middleware
        run endpoint
      end
      result = catch(:result){ Rack::MockRequest.new(app).get('/') }
      result.should == @job
    end
  end

  describe "inspect" do
    it "should be pretty yo" do
      @job.to_app.inspect.should == %(<Dragonfly::JobEndpoint steps=[fetch("egg")] >)
    end
  end

end
