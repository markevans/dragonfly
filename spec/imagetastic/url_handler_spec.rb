require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::UrlHandler do
  
  before(:each) do
    @url_handler = Imagetastic::UrlHandler.new
  end
  
  describe "parsing a query string" do
    
    before(:each) do
      @url_handler.configure{|c| c.protect_from_dos_attacks = false }
      @query_string = 'm=b&opts[d]=e&opts[j]=k'
    end
    
    it "should parse a query string into at least a two level nested hash" do
      @url_handler.query_to_params(@query_string).should == ({
        'm' => 'b',
        'opts' => {
          'd' => 'e',
          'j' => 'k'
        }
      })
    end
    
    it "should return nil for an empty query string" do
      @url_handler.query_to_params('').should be_nil
    end
    
    it "should return nil for a nil query string" do
      @url_handler.query_to_params(nil).should be_nil
    end
    
    %w{m opts}.each do |key|
      it "should accept #{key} as a param key" do
        lambda{
          @url_handler.query_to_params("#{key}=a")
        }.should_not raise_error
      end
    end
    
    it "should not accept the sha key if protection turned off" do
      lambda{
        @url_handler.query_to_params("#{@query_to_params}&sha=abcd1234")
      }.should raise_error(Imagetastic::UrlHandler::BadParams)
    end
    
    it "should reject bad keys" do
      lambda{
        @url_handler.query_to_params("bad_key=a")
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
      @query_string = 'm=b&opts[d]=e&opts[j]=k'
    end
    
    it "should return the params as normal if the sha is ok" do
      Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
      @url_handler.query_to_params("#{@query_string}&sha=thisismysha12345").should == ({
        'm' => 'b',
        'opts' => {
          'd' => 'e',
          'j' => 'k'
        },
        'sha' => 'thisismysha12345'
      })
    end
    
    it "should raise an error if the sha is incorrect" do
      Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
      lambda{
        @url_handler.query_to_params("#{@query_string}&sha=heyNOTmysha12345")
      }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
    end
    
    it "should raise an error if the sha isn't given" do
      lambda{
        @url_handler.query_to_params(@query_string)
      }.should raise_error(Imagetastic::UrlHandler::SHANotGiven)
    end
    
    describe "specifying the SHA length" do

      before(:each) do
        @url_handler.configure{|c|
          c.sha_length = 3
        }
      end

      it "should use a SHA of the specified length" do
          Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
          lambda{
            @url_handler.query_to_params("#{@query_string}&sha=thi")
          }.should_not raise_error
      end

      it "should raise an error if the SHA is correct but too long" do
          Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
          lambda{
            @url_handler.query_to_params("#{@query_string}&sha=this")
          }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
      end

      it "should raise an error if the SHA is correct but too short" do
          Digest::SHA1.should_receive(:hexdigest).and_return("thisismysha12345")
          lambda{
            @url_handler.query_to_params("#{@query_string}&sha=th")
          }.should raise_error(Imagetastic::UrlHandler::IncorrectSHA)
      end
      
    end
    
    it "should use the secret given to create the sha" do
      @url_handler.configure{|c| c.secret = 'digby' }
      Digest::SHA1.should_receive(:hexdigest).with(string_matching(/digby/)).and_return('thisismysha12345')
      @url_handler.query_to_params("#{@query_string}&sha=thisismysha12345")
    end
    
  end
  
end