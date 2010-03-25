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
          env = env_for("/some_uid.png?#{query_string(:thumb, '20x30#ne', :png)}")
          @params = @url_handler.parse_env(env)
        end
        it "should extract the uid" do
          @params.uid.should == 'some_uid'
        end
        it "should extract the job args" do
          @params.job_args.should == [:thumb, '20x30#ne', :png]
        end
        it "should extract the format" do
          @params.format.should == :png
        end
      end

      describe "with a path prefix" do
        before(:each) do
          @url_handler.path_prefix = '/media'
        end
        it "should correctly extract the uid" do
          params = @url_handler.parse_env(env_for("/media/some_uid.png"))
          params.uid.should == 'some_uid'
        end
        it "should raise an UnknownUrl error if the url doesn't have the path prefix" do
          lambda{
            @url_handler.parse_env(env_for("/some_uid.png"))
          }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
        end
      end

      describe "errors" do
        it "should raise an UnknownUrl error if the path doesn't have a uid bit" do
          lambda{
            @url_handler.parse_env(env_for('.hello'))
          }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
        end
  
        it "should raise an UnknownUrl error if the path is only slashes" do
          lambda{
            @url_handler.parse_env(env_for('/./'))
          }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
        end
      end
  
      describe "edge cases" do
        it "should set most of the path as the uid if there is more than one dot" do
          params = @url_handler.parse_env(env_for('/hello.old.bean'))
          params.uid.should == 'hello.old'
          params.format.should == :bean
        end

        it "should set most of the path as the uid if there are more than one slashes" do
          params = @url_handler.parse_env(env_for('/hello/old.bean'))
          params.uid.should == 'hello/old'
          params.format.should == :bean
        end

        it "should unescape any url-escaped characters" do
          params = @url_handler.parse_env(env_for('/hello%20bean.jpg'))
          params.uid.should == 'hello bean'
        end
      end
  
      describe "when no job is given" do
        before(:each) do
          env = env_for("/some_uid.png")
          @params = @url_handler.parse_env(env)
        end
        it "should extract the uid" do
          @params.uid.should == 'some_uid'
        end
        it "should set the job args to nil" do
          @params.job_args.should be_nil
        end
        it "should extract the format" do
          @params.format.should == :png
        end
      end
    end
      
  end
  
  describe "forming a url from parameters" do
    before(:each) do
      @url_handler.protect_from_dos_attacks = false
      @uid = 'thisisunique'
      @format = :gif
      @job_args = [:thumb, '30x40']
    end
    it "should correctly form a query string" do
      @url_handler.params_to_url(@uid, @format, @job_args).should  == '/thisisunique.gif?j=BAhbBzoKdGh1bWIiCjMweDQw'
    end
    it "should correctly form a query string when dos protection turned on" do
      @url_handler.protect_from_dos_attacks = true
      @url_handler.params_to_url(@uid, @format, @job_args).should  == '/thisisunique.gif?j=BAhbBzoKdGh1bWIiCjMweDQw'
    end
    it "should leave out the format if there is none" do
      @url_handler.params_to_url(@uid, nil, @job_args).should == '/thisisunique?j=BAhbBzoKdGh1bWIiCjMweDQw'
    end
    it "should prefix with the path_prefix if there is one" do
      @url_handler.path_prefix = '/images'
      @url_handler.params_to_url(@uid, @format, @job_args).should == '/images/thisisunique.gif?j=BAhbBzoKdGh1bWIiCjMweDQw'
    end
    it "should escape any non-url friendly characters" do
      @url_handler.params_to_url('hello/u u', nil, nil).should == '/hello%2Fu+u'
    end
  end
  
  describe "protecting from DOS attacks with SHA" do
    
    before(:each) do
      @url_handler.configure{|c|
        c.protect_from_dos_attacks = true
        c.secret     = 'secret'
        c.sha_length = 16
      }
      @url = "/some_image.gif?j=BAhbBzoKdGh1bWIiCjMweDQw"
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
  
  describe "#url_for" do
    
    it "should pass parameters from Parameter.from_args plus the uid to params_to_url" do
      parameters_class = Class.new(Dragonfly::Parameters)
      url_handler = Dragonfly::UrlHandler.new(parameters_class)
      parameters_class.should_receive(:from_args).with(:a, :b, :c).and_return parameters_class.new(:processing_method => :resize)
      url_handler.should_receive(:params_to_url).with(parameters_matching(:processing_method => :resize, :uid => 'some_uid')).and_return 'some.url'
      url_handler.url_for('some_uid', :a, :b, :c)
    end
        
  end
  
  describe "sanity check" do
    it "params_to_url should exactly reverse map url_to_parameters" do
      Digest::SHA1.should_receive(:hexdigest).exactly(:twice).and_return('thisismysha12345')
      path = "/images/some_image.gif"
      query_string = "m=b&o[d]=e&o[j]=k&e[l]=m&s=thisismysha12345"
      parameters = @url_handler.url_to_parameters(path, query_string)
      @url_handler.params_to_url(parameters).should match_url("#{path}?#{query_string}")
    end
    
    it "url_to_parameters should exactly reverse map params_to_url" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = true}
      parameters = Dragonfly::Parameters.new(
        :processing_method => 'b',
        :processing_options => {
          :d => 'e',
          :j => 'k'
        },
        :format => 'jpg',
        :encoding => {:x => 'y'},
        :uid => 'thisisunique'
      )
      
      url = @url_handler.params_to_url(parameters)
      @url_handler.url_to_parameters(*url.split('?')).should == parameters
    end
  end
  
end