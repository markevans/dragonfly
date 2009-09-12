require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::UrlHandler do
  
  before(:each) do
    @url_handler = Imagetastic::UrlHandler.new
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
    
    it "should correctly extract the mime type" do
      @parameters.mime_type.should == 'image/jpeg'
    end
    
    it "should correctly extract the processing method" do
      @parameters.processing_method.should == 'b'
    end
    
    it "should correctly extract the options" do
      @parameters.options.should == {:j => 'k', :d => 'e'}
    end
    
    it "should correctly extract the encoding" do
      @parameters.encoding.should == {:l => 'm'}
    end
    
    it "should have options and encoding as optional" do
      parameters = @url_handler.url_to_parameters(@path, 'm=b')
      parameters.options.should == {}
      parameters.encoding.should == {}
    end
    
  end
  
  describe "forming a url from parameters" do
    before(:each) do
      @parameters = Imagetastic::Parameters.new
      @parameters.uid = 'thisisunique'
      @parameters.processing_method = 'b'
      @parameters.options = {:d => 'e', :j => 'k'}
      @parameters.mime_type = 'image/gif'
      @parameters.encoding = {:x => 'y'}
    end
    it "should correctly form a query string when dos protection turned off" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = false}
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y')
    end
    it "should correctly form a query string when dos protection turned on" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = true}
      @parameters.should_receive(:generate_sha).and_return('thisismysha12345')
      @url_handler.parameters_to_url(@parameters).should match_url('/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y&s=thisismysha12345')
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
      @parameters = Imagetastic::Parameters.new
      Imagetastic::Parameters.stub!(:new).and_return(@parameters)
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
      }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
    end
    
    it "should raise an error if the sha isn't given" do
      lambda{
        @url_handler.url_to_parameters(@path, @query_string)
      }.should raise_error(Imagetastic::UrlHandler::SHANotGiven)
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
          }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
      end

      it "should raise an error if the SHA is correct but too short" do
          lambda{
            @url_handler.url_to_parameters(@path, "#{@query_string}&s=th")
          }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
      end
      
    end
    
    it "should use the secret given to create the sha" do
      @url_handler.configure{|c| c.secret = 'digby' }
      Digest::SHA1.should_receive(:hexdigest).with(string_matching(/digby/)).and_return('thisismysha12345')
      @url_handler.url_to_parameters(@path, "#{@query_string}&s=thisismysha12345")
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
      parameters = Imagetastic::Parameters.new(
        :processing_method => 'b',
        :options => {
          :d => 'e',
          :j => 'k'
        },
        :mime_type => 'image/jpeg',
        :encoding => {:x => 'y'},
        :uid => 'thisisunique'
      )
      
      url = @url_handler.parameters_to_url(parameters)
      @url_handler.url_to_parameters(*url.split('?')).should == parameters
    end
  end
  
end