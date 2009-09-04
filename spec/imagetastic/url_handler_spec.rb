require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::UrlHandler do
  
  before(:each) do
    @url_handler = Imagetastic::UrlHandler.new
  end
  
  describe "parsing the query string" do
    
    before(:each) do
      @path = "/images/some_image.jpg"
      @query_string = "m=b&o[d]=e&o[j]=k&e[l]=m"
      @url_handler.configure{|c| c.protect_from_dos_attacks = false }
    end
    
    it "should form the uid from the basename of the url" do
      params = @url_handler.url_to_params(@path, @query_string)
      params[:uid].should == 'images/some_image'
    end
    
    it "should behave the same if there is no beginning slash" do
      params = @url_handler.url_to_params('images/some_image.jpg', @query_string)
      params[:uid].should == 'images/some_image'
    end
    
    it "should put the encoding from the file extension in the encoding part of the hash" do
      params = @url_handler.url_to_params('images/some_image.jpg', @query_string)
      params[:encoding][:mime_type].should == 'image/jpeg'
    end
    
    it "should correctly parse method, options and encoding" do
      params = @url_handler.url_to_params(@path, @query_string)
      params[:encoding][:l].should == 'm'
      params[:method].should == 'b'
      params[:options].should == {:j => 'k', :d => 'e'}
    end

    it "should reject bad keys" do
      lambda{
        @url_handler.url_to_params(@path, "#{@query_string}&bad_key=a")
      }.should raise_error(Imagetastic::UrlHandler::BadParams)
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
    end
    
    it "should not accept the sha key if protection turned off" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = false }
      lambda{
        @url_handler.url_to_params(@path, "#{@query_string}&s=thisismysha12345")
      }.should raise_error(Imagetastic::UrlHandler::BadParams)
    end
    
    it "should not include the sha in the params" do
      Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
      params = @url_handler.url_to_params(@path, "#{@query_string}&s=thisismysha12345")
      params.should_not have_key(:sha)
    end
    
    it "should return the params as normal if the sha is ok" do
      Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
      params = @url_handler.url_to_params(@path, "#{@query_string}&s=thisismysha12345")
      params.should have_key(:method)
      params.should have_key(:options)
      params.should have_key(:encoding)
    end
    
    it "should raise an error if the sha is incorrect" do
      Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
      lambda{
        @url_handler.url_to_params(@path, "#{@query_string}&s=heyNOTmysha12345")
      }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
    end
    
    it "should raise an error if the sha isn't given" do
      lambda{
        @url_handler.url_to_params(@path, @query_string)
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
            @url_handler.url_to_params(@path, "#{@query_string}&s=thi")
          }.should_not raise_error
      end

      it "should raise an error if the SHA is correct but too long" do
          lambda{
            @url_handler.url_to_params(@path, "#{@query_string}&s=this")
          }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
      end

      it "should raise an error if the SHA is correct but too short" do
          lambda{
            @url_handler.url_to_params(@path, "#{@query_string}&s=th")
          }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
      end
      
    end
    
    it "should use the secret given to create the sha" do
      @url_handler.configure{|c| c.secret = 'digby' }
      Digest::SHA1.should_receive(:hexdigest).with(string_matching(/digby/)).and_return('thisismysha12345')
      @url_handler.url_to_params(@path, "#{@query_string}&s=thisismysha12345")
    end
    
  end
  
  describe "forming a url from params" do
    before(:each) do
      @params = {
        :method => 'b',
        :options => {
          :d => 'e',
          :j => 'k'
        },
        :encoding => {:x => 'y', :mime_type => 'image/gif'},
        :uid => 'thisisunique'
      }
      @url = '/thisisunique.gif?m=b&o[d]=e&o[j]=k&e[x]=y'
    end
    it "should correctly form a query string when DOS protection off" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = false }
      @url_handler.params_to_url(@params).should match_url(@url)
    end
    it "should correctly form a query string when DOS protection on" do
      @url_handler.configure{|c| c.protect_from_dos_attacks = true }
      Digest::SHA1.should_receive(:hexdigest).and_return('thisismysha12345')
      @url_handler.params_to_url(@params).should match_url(@url + '&s=thisismysha12345')
    end
    
  end
  
  describe "sanity check" do
    it "params_to_url should exactly reverse map url_to_params" do
      Digest::SHA1.should_receive(:hexdigest).exactly(:twice).and_return('thisismysha12345')
      path = "/images/some_image.gif"
      query_string = "m=b&o[d]=e&o[j]=k&e[l]=m&s=thisismysha12345"
      params = @url_handler.url_to_params(path, query_string)
      @url_handler.params_to_url(params).should match_url("#{path}?#{query_string}")
    end
    
    it "url_to_params should exactly reverse map params_to_url" do
      params = {
        :method => 'b',
        :options => {
          :d => 'e',
          :j => 'k'
        },
        :encoding => {:x => 'y', :mime_type => 'image/jpeg'},
        :uid => 'thisisunique'
      }
      
      url = @url_handler.params_to_url(params)
      @url_handler.url_to_params(*url.split('?')).should == params
    end
  end
  
end