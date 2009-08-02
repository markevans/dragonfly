require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::UrlHandler do
  
  before(:each) do
    @obj = Object.new
    @obj.extend(Imagetastic::UrlHandler)
  end
  
  describe "parsing a query string" do
    
    it "should parse a query string into at least a two level nested hash" do
      @obj.query_to_params('a=b&c[d]=e&c[j]=k&f[g]=h').should == ({
        'a' => 'b',
        'c' => {
          'd' => 'e',
          'j' => 'k'
        },
        'f' => {
          'g' => 'h'
        }
      })
    end
    
  end
  
end