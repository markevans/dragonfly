require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::UrlHandler do
  
  before(:each) do
    @url_handler = Imagetastic::UrlHandler.new
  end
  
  describe "parsing a query string" do
    
    before(:each) do
      @url_handler.configure{|c| c.protect_from_dos_attacks = false }
    end
    
    it "should parse a query string into at least a two level nested hash" do
      @url_handler.query_to_params('m=b&opts[d]=e&opts[j]=k').should == ({
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
      pending "DOS stuff"
    end
    
    it "should reject bad keys" do
      lambda{
        @url_handler.query_to_params("bad_key=a")
      }.should raise_error(Imagetastic::UrlHandler::BadParams)
    end
    
  end
  
  describe "protecting from DOS attacks with SHA" do
    
    before(:each) do
      @url_handler.configure{|c| c.protect_from_dos_attacks = true }
    end

    it "should accept 'sha' as a valid param key"
    it "should return the params as normal if the sha is ok"
    it "should raise an error if the sha is incorrect"
    it "should raise an error if the sha isn't given"
    it "should use a sha of the specified length"
    it "should use the secret given to create the sha"
  end
  
end