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
  
  def query_string(*args)
    "j=#{marshal_encode(args)}"
  end
  
  describe "extracting parameters from the url" do

    describe "without dos protection" do
      before(:each) do
        @url_handler.protect_from_dos_attacks = false
      end
      
      describe "normal usage" do
        before(:each) do
          env = env_for("/some_uid?#{query_string(:thumb, '20x30#ne', :png)}")
          @params = @url_handler.parse_env(env)
        end
        it "should extract the uid" do
          @params.uid.should == 'some_uid'
        end
        it "should extract the job" do
          @params.job_name.should == :thumb
          @params.job_args.should == ['20x30#ne', :png]
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
        it "should raise an UnknownUrl error if the url doesn't have the path prefix" do
          lambda{
            @url_handler.parse_env(env_for("/some_uid"))
          }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
        end
      end

      describe "errors" do
        it "should raise an UnknownUrl error if the path doesn't have a uid bit" do
          lambda{
            @url_handler.parse_env(env_for('/'))
          }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
        end
      end
  
      describe "edge cases" do
        it "should include any dot suffixes in the uid" do
          params = @url_handler.parse_env(env_for('/hello.there'))
          params.uid.should == 'hello.there'
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
        it "should set the job args to nil" do
          @params.job_name.should be_nil
          @params.job_args.should be_nil
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
      @url_handler.url_for(@uid, *@job).should  == "/thisisunique?j=#{@encoded_job}"
    end
    it "should correctly form a query string when dos protection turned on" do
      @url_handler.protect_from_dos_attacks = true
      @url_handler.url_for(@uid, *@job).should  == "/thisisunique?j=#{@encoded_job}&s=263974197e42b382"
    end
    it "should not append the job query string if not set" do
      @url_handler.url_for(@uid).should  == '/thisisunique'
    end
    it "should prefix with the path_prefix if there is one" do
      @url_handler.path_prefix = '/images'
      @url_handler.url_for(@uid, *@job).should == "/images/thisisunique?j=#{@encoded_job}"
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
      @url = "/some_image?j=BAhbBzoKdGh1bWIiCjMweDQw"
      @correct_sha = "428ee97948379e63"
    end
    
    it "should return the parameters as normal if the sha is ok" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}&s=#{@correct_sha}"))
      }.should_not raise_error
    end
    
    it "should raise an error if the sha is incorrect" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}&s=heyNOTmysha12345"))
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
            @url_handler.parse_env(env_for("#{@url}&s=428"))
          }.should_not raise_error
      end

      it "should raise an error if the SHA is correct but too long" do
          lambda{
            @url_handler.parse_env(env_for("#{@url}&s=428e"))
          }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
      end

      it "should raise an error if the SHA is correct but too short" do
          lambda{
            @url_handler.parse_env(env_for("#{@url}&s=42"))
          }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
      end
      
    end
    
    it "should use the secret given to create the sha" do
      lambda{
        @url_handler.parse_env(env_for("#{@url}&s=#{@correct_sha}"))
      }.should_not raise_error
      @url_handler.secret = 'digby'
      lambda{
        @url_handler.parse_env(env_for("#{@url}&s=#{@correct_sha}"))
      }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
    end
    
  end
  
  describe "sanity check" do

    before(:each) do
      @job = [:thumb, '20x30#ne', :png]
      @url = "/some_uid?#{query_string(*@job)}&s=79e7f63d9eb51c2e"
    end

    it "url_for should exactly reverse map parse_env" do
      params = @url_handler.parse_env(env_for(@url))
      @url_handler.url_for('some_uid', params.job_name, *params.job_args).should == @url
    end
    
    it "parse_env should exactly reverse map url_for" do
      url = @url_handler.url_for('some_uid', *@job)
      params = @url_handler.parse_env(env_for(url))
      
      params.uid.should == 'some_uid'
      params.job_name.should == :thumb
      params.job_args.should == ['20x30#ne', :png]
    end
  end
  
end