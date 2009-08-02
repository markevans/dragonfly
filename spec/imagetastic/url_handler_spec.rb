require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::UrlHandler do
  
  before(:each) do
    @url_handler = Imagetastic::UrlHandler.new
  end
  
  describe "parsing a query string" do
    
    it "should parse a query string into at least a two level nested hash" do
      @url_handler.query_to_params('m=b&opts[d]=e&opts[j]=k&sha=abcd').should == ({
        'm' => 'b',
        'opts' => {
          'd' => 'e',
          'j' => 'k'
        },
        'sha' => 'abcd'
      })
    end
    
    it "should return nil for an empty query string" do
      @url_handler.query_to_params('').should be_nil
    end
    
    it "should return nil for a nil query string" do
      @url_handler.query_to_params(nil).should be_nil
    end
    
    %w{m opts sha}.each do |key|
      it "should accept #{key} as a param key" do
        lambda{
          @url_handler.query_to_params("#{key}=a")
        }.should_not raise_error
      end
    end
    
    it "should reject bad keys" do
      lambda{
        @url_handler.query_to_params("bad_key=a")
      }.should raise_error(Imagetastic::UrlHandler::BadParams)
    end
    
  end
  
end