# encoding: utf-8
require 'spec_helper'

## General tests for Response go here as it's a pretty simple wrapper around that

describe "Dragonfly::JobEndpoint Rack::Lint tests" do
  before(:each) do
    @app = test_app
    @app.add_generator(:test_data){|content| content.update("Test Data") }
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
    uri = opts[:path] || ""
    Rack::MockRequest.new(endpoint).request(method, uri, opts)
  end

  before(:each) do
    @app = test_app
    uid = @app.store("GUNGLE", 'name' => 'gung.txt')
    @job = @app.fetch(uid)
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
      response.body.should == "method not allowed"
    end

  end

  it "should return 404 if the datastore raises NotFound" do
    @job.should_receive(:apply).and_raise(Dragonfly::Job::Fetch::NotFound)
    response = make_request(@job)
    response.status.should == 404
  end

  it "returns a 500 for any runtime error" do
    @job.should_receive(:apply).and_raise(RuntimeError, "oh dear")
    Dragonfly.should_receive(:warn).with(/oh dear/)
    response = make_request(@job)
    response.status.should == 500
  end

  describe "default content disposition file name" do
    before do
      uid = @app.store("GUNGLE", 'name' => 'güng.txt')
      @job = @app.fetch(uid)
    end

    it "doesn't encode utf8 characters" do
      response = make_request(@job)
      response['Content-Disposition'].should == 'filename="güng.txt"'
    end

    it "does encode them if the request is from IE" do
      response = make_request(@job, 'HTTP_USER_AGENT' => "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; el-GR)")
      response['Content-Disposition'].should == 'filename="g%C3%BCng.txt"'
    end
  end

  describe "logging" do
    it "logs successful requests" do
      Dragonfly.should_receive(:info).with("GET /something?great 200")
      make_request(@job, :path => '/something?great')
    end
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
        @job.should_receive(:signature).at_least(:once).and_return('dingle')
        response = make_request(@job, 'HTTP_IF_NONE_MATCH' => header)
        response.status.should == 304
        response['ETag'].should == '"dingle"'
        response['Cache-Control'].should == "public, max-age=31536000"
        response.body.should be_empty
      end
    end

    it "should not have applied any steps if the correct ETag is specified in HTTP_IF_NONE_MATCH header" do
      response = make_request(@job, 'HTTP_IF_NONE_MATCH' => @job.signature)
      @job.applied_steps.should be_empty
    end
  end

  describe "custom headers" do
    before(:each) do
      @app.configure{ response_header 'This-is', 'brill' }
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
      @app.response_headers['Cache-Control'] = proc{|job, request, headers|
        [job.basename.reverse.upcase, request['a'], headers['Cache-Control'].chars.first].join(',')
      }
      response = make_request(@job, 'QUERY_STRING' => 'a=egg')
      response['Cache-Control'].should == 'GNUG,egg,p'
    end
    it "should allow removing by setting to nil" do
      @app.response_headers['Cache-Control'] = nil
      make_request(@job).headers.should_not have_key('Cache-Control')
    end
  end

  describe "setting the job in the env for communicating with other rack middlewares" do
    before(:each) do
      @app.add_generator(:test_data){ "TEST DATA" }
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
      @job.to_app.inspect.should =~ %r{<Dragonfly::JobEndpoint steps=.* >}
    end
  end

end
