require 'spec_helper'

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
  
  describe "to_pathname" do
    before(:each) do
      @pathname = "hello/there".to_pathname
    end
    it "should return a pathname" do
      @pathname.should be_a(Pathname)
    end
    it "should be the correct path" do
      @pathname.to_s.should == 'hello/there'
    end
  end
  
end
