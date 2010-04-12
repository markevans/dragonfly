# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::UrlHandler do
  
  include Dragonfly::Serializer
  
  before(:each) do
    @url_handler = Dragonfly::UrlHandler.new
  end

  def env_for(url)
    Rack::MockRequest.env_for("http://doogie.com#{url}")
  end
  
  describe "extracting parameters from the url" do

    describe "without dos protection" do
      before(:each) do
        @url_handler.protect_from_dos_attacks = false
      end
      
      describe "normal usage" do
        before(:each) do
          env = env_for("/some_uid?job=asdf")
          @params = @url_handler.parse_env(env)
        end
        it "should extract the uid" do
          @params.uid.should == 'some_uid'
        end
        it "should extract the job" do
          @params.job_name.should == :thumb
          @params.job_opts.should == {:size => '20x30#ne', :format => :png}
        end
      end

      describe "with a path prefix" do
        before(:each) do
          @url_handler.path_prefix = '/media'
        end
        it "should correctly extract the uid" do
          params = @url_handler.parse_env(env_for("/media/some_uid"))
          params.uid.should == 'some_uid'
        end
        it "should raise a NotFound error if the url doesn't have the path prefix" do
          lambda{
            @url_handler.parse_env(env_for("/some_uid"))
          }.should raise_error(Dragonfly::Route::NotFound)
        end
      end

      describe "errors" do
        it "should raise a NotFound error if the path doesn't have a uid bit" do
          lambda{
            @url_handler.parse_env(env_for('/'))
          }.should raise_error(Dragonfly::Route::NotFound)
        end
      end
  
      describe "when no job is given" do
        before(:each) do
          env = env_for("/some_uid")
          @params = @url_handler.parse_env(env)
        end
        it "should extract the uid" do
          @params.uid.should == 'some_uid'
        end
        it "should set the job to nil" do
          @params.job_name.should be_nil
          @params.job_opts.should be_nil
        end
      end
    end
      
  end
  
  describe "forming a url from parameters" do
    before(:each) do
      @url_handler.protect_from_dos_attacks = false
      @uid = 'thisisunique'
      @job = [:thumb, '30x40']
      @encoded_job = 'BAhbBzoKdGh1bWJJIgozMHg0MAY6DWVuY29kaW5nIgpVVEYtOA'
    end
    it "should correctly form a query string" do
      @url_handler.url_for(@uid, :thumb, :size => '30x40').should  == "/thisisunique?job=#{@encoded_job}"
    end
    it "should correctly form a query string when dos protection turned on" do
      @url_handler.protect_from_dos_attacks = true
      @url_handler.url_for(@uid, :thumb, :size => '30x40').should  == "/thisisunique?job=#{@encoded_job}&sha=263974197e42b382"
    end
    it "should not append the job query string if not set" do
      @url_handler.url_for(@uid).should  == '/thisisunique'
    end
    it "should prefix with the path_prefix if there is one" do
      @url_handler.path_prefix = '/images'
      @url_handler.url_for(@uid, :thumb, :size => '30x40').should == "/images/thisisunique?job=#{@encoded_job}"
    end
    it "should escape any non-url friendly characters" do
      @url_handler.url_for('hello/u u').should == '/hello%2Fu+u'
    end
  end
  
  describe "protecting from DOS attacks with SHA" do
    
    before(:each) do
      @url_handler.configure{|c|
        c.protect_from_dos_attacks = true
        c.secret     = 'secret'
        c.sha_length = 16
      }
      @url = "/some_image?job=BAhbBzoKdGh1bWIiCjMweDQw"
      @correct_sha = "428ee97948379e63"
    end
    
    it "should return the parameters as normal if the sha is ok" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}&sha=#{@correct_sha}"))
      }.should_not raise_error
    end
    
    it "should raise an error if the sha is incorrect" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}&sha=heyNOTmysha12345"))
      }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
    end
    
    it "should raise an error if the sha isn't given" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}"))
      }.should raise_error(Dragonfly::UrlHandler::SHANotGiven)
    end
    
    describe "specifying the SHA length" do

      before(:each) do
        @url_handler.configure{|c|
          c.sha_length = 3
        }
      end

      it "should use a SHA of the specified length" do
          lambda{
            @url_handler.parse_env(env_for("#{@url}&sha=428"))
          }.should_not raise_error
      end

      it "should raise an error if the SHA is correct but too long" do
          lambda{
            @url_handler.parse_env(env_for("#{@url}&sha=428e"))
          }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
      end

      it "should raise an error if the SHA is correct but too short" do
          lambda{
            @url_handler.parse_env(env_for("#{@url}&sha=42"))
          }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
      end
      
    end
    
    it "should use the secret given to create the sha" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}&sha=#{@correct_sha}"))
      }.should_not raise_error
      @url_handler.secret = 'digby'
      lambda{
        @url_handler.parse_env(env_for("#{@url}&sha=#{@correct_sha}"))
      }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
    end
    
  end
  
  describe "sanity check" do

    before(:each) do
      @uid = 'some_uid'
      @job_name = :thumb
      @job_opts = {:size => '20x30#ne', :format => :png}
      @url = "/some_uid?asdfsadf&sha=79e7f63d9eb51c2e"
    end

    it "url_for should exactly reverse map parse_env" do
      params = @url_handler.parse_env(env_for(@url))
      url = @url_handler.url_for(params.uid, params.job_name, params.job_opts)
      
      url.should == @url
    end
    
    it "parse_env should exactly reverse map url_for" do
      url = @url_handler.url_for(@uid, @job_name, @job_opts)
      params = @url_handler.parse_env(env_for(url))
      
      params.uid.should == @uid
      params.job_name.should == @job_name
      params.job_opts.should == @job_opts
    end
  end
  
end