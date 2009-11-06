require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::UrlHandler do
  
  before(:each) do
    @url_handler = Dragonfly::UrlHandler.new
  end
  
  describe "extracting parameters from the url" do
    
    before(:each) do
      @url_handler.configure{|c| c.protect_from_dos_attacks = false}
      @path = "/images/some_image.jpg"
      @query_string = "m=b&o[d]=e&o[j]=k&e[l]=m"
      @parameters = @url_handler.url_to_parameters(@path, @query_string)
    end
    
    it "should correctly extract the uid" do
      @parameters.uid.should == 'images/some_image'
    end
    
    it "should behave the same if there is no beginning slash" do
      parameters = @url_handler.url_to_parameters('images/some_image.jpg', @query_string)
      parameters.uid.should == 'images/some_image'
    end
    
    it "should take into account the path prefix if there is one" do
      @url_handler.path_prefix = '/images'
      parameters = @url_handler.url_to_parameters('/images/2009/some_image.jpg', @query_string)
      parameters.uid.should == '2009/some_image'
    end
    
    it "should correctly extract the format" do
      @parameters.format.should == 'jpg'
    end
    
    it "should correctly extract the processing method" do
      @parameters.processing_method.should == 'b'
    end
    
    it "should correctly extract the processing_options" do
      @parameters.processing_options.should == {:j => 'k', :d => 'e'}
    end
    
    it "should correctly extract the encoding" do
      @parameters.encoding.should == {:l => 'm'}
    end
    
    it "should have processing_options and encoding as optional" do
      parameters = @url_handler.url_to_parameters(@path, 'm=b')
      parameters.processing_options.should == {}
      parameters.encoding.should == {}
    end
    
    it "should use the parameters class passed in if initialized with one" do
      parameters_class = mock('parameters_class')
      url_handler = Dragonfly::UrlHandler.new(parameters_class)
      url_handler.stub!(:validate_parameters)
      parameters_class.should_receive(:new)
      url_handler.url_to_parameters(@path, @query_string)
    end
    
    it "should raise a 404 error if the path doesn't have an extension" do
      lambda{
        @url_handler.url_to_parameters('hello', @query_string)
      }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
    end

    it "should raise a 404 error if the path doesn't have a uid bit" do
      lambda{
        @url_handler.url_to_parameters('.hello', @query_string)
      }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
    end
    
    it "should raise a 404 error if the path is only slashes" do
      lambda{
        @url_handler.url_to_parameters('/./', @query_string)
      }.should raise_error(Dragonfly::UrlHandler::UnknownUrl)
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
    it "should leave out any empty parameters" do
      @parameters.processing_options = {}
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?m=b&e[x]=y')
    end
    it "should prefix with the path_prefix if there is one" do
      @url_handler.path_prefix = '/images'
      @url_handler.parameters_to_url(@parameters).should match_url('/images/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y')
    end
    it "should validate the parameters" do
      @parameters.should_receive(:validate!)
      @url_handler.parameters_to_url(@parameters)
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