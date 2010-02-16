require File.dirname(__FILE__) + '/../../spec_helper'

describe String do
  
  describe "to_method_name" do
    if RUBY_VERSION =~ /^1.8/
      it "should return a string" do
        'hello'.to_method_name.should == 'hello'
      end
    else
      it "should return a symbol" do
        'hello'.to_method_name.should == :hello
      end
    end
  end
  
end
