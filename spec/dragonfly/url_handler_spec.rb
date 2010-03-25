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
      @parameters = Dragonfly::Parameters.new
      @parameters.uid = 'thisisunique'
      @parameters.processing_method = 'b'
      @parameters.processing_options = {:d => 'e', :j => 'k'}
      @parameters.format = :gif
      @parameters.encoding = {:x => 'y'}
      @url_handler.configure{|c| c.protect_from_dos_attacks = false}
    end
    it "should correctly form a query string" do
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y')
    end
    it "should correctly form a query string when dos protection turned on" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = true}
      @parameters.should_receive(:generate_sha).and_return('thisismysha12345')
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y&s=thisismysha12345')
    end
    it "should leave out any nil parameters" do
      @parameters.processing_method = nil
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?o[d]=e&o[j]=k&e[x]=y')
    end
    it "should leave out the format if there is none" do
      @parameters.format = nil
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique?m=b&o[d]=e&o[j]=k&e[x]=y')
    end
    it "should leave out any empty parameters" do
      @parameters.processing_options = {}
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?m=b&e[x]=y')
    end
    it "should prefix with the path_prefix if there is one" do
      @url_handler.path_prefix = '/images'
      @url_handler.parameters_to_url(@parameters).should match_url('/images/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y')
    end
    it "should escape any non-url friendly characters except for '/'" do
      parameters = Dragonfly::Parameters.new :uid => 'hello/u"u', :processing_method => 'm"m', :format => 'jpg'
      @url_handler.parameters_to_url(parameters).should == '/hello/u%22u.jpg?m=m%22m'
    end
  end
  
  describe "protecting from DOS attacks with SHA" do
    
    before(:each) do
      @url_handler.configure{|c|
        c.protect_from_dos_attacks = true
        c.secret     = 'secret'
        c.sha_length = 16
      }
      @path = "/images/some_image.jpg"
      @query_string = "m=b&o[d]=e&o[j]=k"
      @parameters = Dragonfly::Parameters.new
      Dragonfly::Parameters.stub!(:new).and_return(@parameters)
    end
    
    it "should return the parameters as normal if the sha is ok" do
      @parameters.should_receive(:generate_sha).with('secret', 16).and_return('thisismysha12345')
      lambda{
        @url_handler.url_to_parameters(@path, "#{@query_string}&s=thisismysha12345")
      }.should_not raise_error
    end
    
    it "should raise an error if the sha is incorrect" do
      @parameters.should_receive(:generate_sha).with('secret', 16).and_return('thisismysha12345')
      lambda{
        @url_handler.url_to_parameters(@path, "#{@query_string}&s=heyNOTmysha12345")
      }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
    end
    
    it "should raise an error if the sha isn't given" do
      lambda{
        @url_handler.url_to_parameters(@path, @query_string)
      }.should raise_error(Dragonfly::UrlHandler::SHANotGiven)
    end
    
    describe "specifying the SHA length" do

      before(:each) do
        @url_handler.configure{|c|
          c.sha_length = 3
        }
        Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
      end

      it "should use a SHA of the specified length" do
          lambda{
            @url_handler.url_to_parameters(@path, "#{@query_string}&s=thi")
          }.should_not raise_error
      end

      it "should raise an error if the SHA is correct but too long" do
          lambda{
            @url_handler.url_to_parameters(@path, "#{@query_string}&s=this")
          }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
      end

      it "should raise an error if the SHA is correct but too short" do
          lambda{
            @url_handler.url_to_parameters(@path, "#{@query_string}&s=th")
          }.should raise_error(Dragonfly::UrlHandler::IncorrectSHA)
      end
      
    end
    
    it "should use the secret given to create the sha" do
      @url_handler.configure{|c| c.secret = 'digby' }
      Digest::SHA1.should_receive(:hexdigest).with(string_matching(/digby/)).and_return('thisismysha12345')
      @url_handler.url_to_parameters(@path, "#{@query_string}&s=thisismysha12345")
    end
    
  end
  
  describe "#url_for" do
    
    it "should pass parameters from Parameter.from_args plus the uid to parameters_to_url" do
      parameters_class = Class.new(Dragonfly::Parameters)
      url_handler = Dragonfly::UrlHandler.new(parameters_class)
      parameters_class.should_receive(:from_args).with(:a, :b, :c).and_return parameters_class.new(:processing_method => :resize)
      url_handler.should_receive(:parameters_to_url).with(parameters_matching(:processing_method => :resize, :uid => 'some_uid')).and_return 'some.url'
      url_handler.url_for('some_uid', :a, :b, :c)
    end
        
  end
  
  describe "sanity check" do
    it "parameters_to_url should exactly reverse map url_to_parameters" do
      Digest::SHA1.should_receive(:hexdigest).exactly(:twice).and_return('thisismysha12345')
      path = "/images/some_image.gif"
      query_string = "m=b&o[d]=e&o[j]=k&e[l]=m&s=thisismysha12345"
      parameters = @url_handler.url_to_parameters(path, query_string)
      @url_handler.parameters_to_url(parameters).should match_url("#{path}?#{query_string}")
    end
    
    it "url_to_parameters should exactly reverse map parameters_to_url" do
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
      
      url = @url_handler.parameters_to_url(parameters)
      @url_handler.url_to_parameters(*url.split('?')).should == parameters
    end
  end
  
end