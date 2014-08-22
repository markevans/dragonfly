require 'spec_helper'
require 'rack/mock'

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

    describe "successful requests" do
      before(:each) do
        @server.url_format = '/media/:job/:name.:format'
      end

      [
        '',
        '/name',
        '/name.ext'
      ].each do |suffix|

        it "should return successfully when given the url with suffix #{suffix.inspect} and the correct sha parameter" do
          url = "/media/#{@job.serialize}#{suffix}?sha=#{@job.sha}"
          response = request(@server, url)
          response.status.should == 200
          response.body.should == 'HELLO THERE'
          response.content_type.should == 'application/octet-stream'
        end

      end

      it "should return successfully without a sha if protection is off" do
        @server.verify_urls = false
        url = "/media/#{@job.serialize}"
        response = request(@server, url)
        response.status.should == 200
        response.body.should == 'HELLO THERE'
      end

      it "should return a cacheable response" do
        url = "/media/#{@job.serialize}?sha=#{@job.sha}"
        response = request(@server, url)
        response.status.should == 200
        response.headers['Cache-Control'].should == "public, max-age=31536000"
      end

      it "should return successfully even if the job is in the query string" do
        @server.url_format = '/'
        url = "/?job=#{@job.serialize}&sha=#{@job.sha}"
        response = request(@server, url)
        response.status.should == 200
        response.body.should == 'HELLO THERE'
      end
    end

    describe "unsuccessful requests" do
      it "should return a 400 if no sha given" do
        url = "/media/#{@job.serialize}"
        response = request(@server, url)
        response.status.should == 400
      end

      it "should return a 400 if wrong sha given" do
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
        url = "/media/#{Dragonfly::Serializer.json_b64_encode([['egg', {'some' => 'args'}]])}"
        response = request(@server, url)
        response.status.should == 404
        response.body.should == 'Not found'
        response.content_type.should == 'text/plain'
        response.headers['X-Cascade'].should be_nil
      end

      it "should return a 403 Forbidden when someone uses fetch_url" do
        response = request(@server, "/media/#{@app.fetch_url('some.url').serialize}")
        response.status.should == 403
        response.body.should == 'Forbidden'
        response.content_type.should == 'text/plain'
      end
    end

    describe "whitelists" do
      def assert_ok(job)
        response = request(@server, "/media/#{job.serialize}")
        response.status.should == 200
      end

      def assert_forbidden(job)
        response = request(@server, "/media/#{job.serialize}")
        response.status.should == 403
        response.body.should == 'Forbidden'
        response.content_type.should == 'text/plain'
      end

      before do
        @server.verify_urls = false
      end

      describe "fetch_file" do
        it "should return a 403 Forbidden when someone uses fetch_file " do
          assert_forbidden @app.fetch_file('samples/egg.png')
        end

        it "returns OK when on whitelist (using full path)" do
          @server.add_to_fetch_file_whitelist [File.expand_path('samples/egg.png')]
          assert_ok @app.fetch_file('samples/egg.png')
        end
      end

      describe "fetch_url" do
        let (:url) {'some.org/path:3000/boogie?yes=please'}

        it "should return a 403 Forbidden when someone uses fetch_url " do
          assert_forbidden @app.fetch_url(url)
        end

        it "returns OK when on whitelist (using full url)" do
          stub_request(:get, url).to_return(:status => 200)
          @server.add_to_fetch_url_whitelist ["http://#{url}"]
          assert_ok @app.fetch_url(url)
        end
      end
    end
  end

  describe "dragonfly response" do
    before(:each) do
      @app = test_app
      @server = Dragonfly::Server.new(@app)
      @server.url_format = '/media/:job'
    end

    it "should return a simple text response" do
      request(@server, '/dragonfly').should be_a_text_response
    end

    it "should be configurable" do
      @server.dragonfly_url = '/hello'
      request(@server, '/hello').should be_a_text_response
      request(@server, '/dragonfly').status.should == 404
    end

    it "should be possible to turn it off" do
      @server.dragonfly_url = nil
      request(@server, '/').status.should == 404
      request(@server, '/dragonfly').status.should == 404
    end
  end

  describe "urls" do

    let (:app) { test_app }
    let (:server) { Dragonfly::Server.new(app) }
    let (:job) { app.fetch("some_uid") }

    describe "params" do
      before(:each) do
        server.url_format = '/media/:job/:zoo'
        server.verify_urls = false
      end
      it "substitutes the relevant params" do
        server.url_for(job).should == "/media/#{job.serialize}"
      end
      it "adds given params" do
        server.url_for(job, :zoo => 'jokes', :on => 'me').should == "/media/#{job.serialize}/jokes?on=me"
      end
      it "uses the url_attr if it exists" do
        job.url_attributes.zoo = 'hair'
        server.url_for(job).should == "/media/#{job.serialize}/hair"
      end
      it "doesn't add any url_attributes that aren't needed" do
        job.url_attributes.gump = 'flub'
        server.url_for(job).should == "/media/#{job.serialize}"
      end
      it "overrides if a param is passed in" do
        job.url_attributes.zoo = 'hair'
        server.url_for(job, :zoo => 'dare').should == "/media/#{job.serialize}/dare"
      end

      describe "basename" do
        before(:each) do
          server.url_format = '/:job/:basename'
          server.verify_urls = false
        end
        it "should use the name" do
          job.url_attributes.name = 'hello.egg'
          server.url_for(job).should == "/#{job.serialize}/hello"
        end
        it "should not set if neither exist" do
          server.url_for(job).should == "/#{job.serialize}"
        end
      end

      describe "ext" do
        before(:each) do
          server.url_format = '/:job.:ext'
          server.verify_urls = false
        end
        it "should use the name" do
          job.url_attributes.name = 'hello.egg'
          server.url_for(job).should == "/#{job.serialize}.egg"
        end
        it "should not set if neither exist" do
          server.url_for(job).should == "/#{job.serialize}"
        end
      end
    end

    describe "host" do
      before do
        server.verify_urls = false
      end

      it "should add the host to the url if configured" do
        server.url_host = 'http://some.server:4000'
        server.url_for(job).should == "http://some.server:4000/#{job.serialize}"
      end

      it "should add the host to the url if passed in" do
        server.url_for(job, :host => 'https://bungle.com').should == "https://bungle.com/#{job.serialize}"
      end

      it "should favour the passed in host" do
        server.url_host = 'http://some.server:4000'
        server.url_for(job, :host => 'https://smeedy').should == "https://smeedy/#{job.serialize}"
      end
    end

    describe "path_prefix" do
      before do
        server.url_format = '/media/:job'
        server.verify_urls = false
      end

      it "adds the path_prefix to the url if configured" do
        server.url_path_prefix = '/logs'
        server.url_for(job).should == "/logs/media/#{job.serialize}"
      end

      it "favours the passed in path_prefix" do
        server.url_path_prefix = '/logs'
        server.url_for(job, :path_prefix => '/bugs').should == "/bugs/media/#{job.serialize}"
      end

      it "goes after the host" do
        server.url_for(job, :path_prefix => '/bugs', :host => 'http://wassup').should == "http://wassup/bugs/media/#{job.serialize}"
      end
    end

    describe "URL verification" do
      it "should generate a URL with a sha parameter by default" do
        server.url_for(job).should == "/#{job.serialize}?sha=#{job.sha}"
      end
    end

  end

  describe "before_serve callback" do

    before(:each) do
      @app = test_app
      @app.add_generator(:test){|content| content.update("TEST") }
      @server = Dragonfly::Server.new(@app)
      @job = @app.generate(:test)
    end

    context "with no stop in the callback" do
      before(:each) do
        @x = x = ""
        @server.before_serve do |job, env|
          x << job.data
        end
      end

      it "should be called before serving" do
        response = request(@server, "/#{@job.serialize}?sha=#{@job.sha}")
        response.body.should == 'TEST'
        @x.should == 'TEST'
      end

      it "should not be called before serving a 404 page" do
        response = request(@server, "blah")
        response.status.should == 404
        @x.should == ""
      end
    end

    context "with a throw :halt in the callback" do
      before(:each) do
        @server.before_serve do |job, env|
          throw :halt, [200, {}, ['hello']]
        end
        @server.verify_urls = false
      end

      it 'return the specified response instead of job.result' do
        response = request(@server, "/#{@job.serialize}")
        response.body.should == 'hello'
      end

      it "should not apply the job if not asked to" do
        @app.generators.get(:test).should_not_receive(:call)
        response = request(@server, "/#{@job.serialize}")
      end
    end

  end

end
