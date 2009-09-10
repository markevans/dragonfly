require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::Parameters do
  
  describe "initializing" do
    it "should allow initializing without a hash" do
      parameters = Imagetastic::Parameters.new
      parameters.uid.should be_nil
    end
    it "should allow initializing with a hash" do
      parameters = Imagetastic::Parameters.new(:uid => 'b')
      parameters.uid.should == 'b'
    end
  end
  
  describe "accessors" do
    before(:each) do
      @parameters = Imagetastic::Parameters.new
    end
    it "should give the accessors the correct defaults" do
      @parameters.uid.should be_nil
      @parameters.method.should be_nil
      @parameters.mime_type.should be_nil
      @parameters.options.should == {}
      @parameters.encoding.should == {}
    end
    it "should provide writers too" do
      @parameters.uid = 'hello'
      @parameters.uid.should == 'hello'
    end
  end
  
  describe "array style accessors" do
    before(:each) do
      @parameters = Imagetastic::Parameters.new(:uid => 'hello')
    end
    it "should be the same as calling the corresponding reader" do
      @parameters[:uid].should == @parameters.uid
    end
    it "should be the same as calling the corresponding writer" do
      @parameters[:uid] = 'goodbye'
      @parameters.uid.should == 'goodbye'
    end
  end
  
  describe "comparing" do
    before(:each) do
      attributes = {
        :uid => 'a',
        :method => 'b',
        :mime_type => 'image/gif',
        :options => {:a => 'b'},
        :encoding => {:c => 'd'}
      }
      @parameters1 = Imagetastic::Parameters.new(attributes)
      @parameters2 = Imagetastic::Parameters.new(attributes)      
    end
    it "should return true when two have all the same attributes" do
      @parameters1.should == @parameters2
    end
    %w(uid method mime_type options encoding).each do |attribute|
      it "should return false when #{attribute} is different" do
        @parameters2[attribute.to_sym] = 'fish'
        @parameters1.should_not == @parameters2
      end
    end
  end
  
  describe "to_hash" do
    it "should return the attributes as a hash" do
      attributes = {
        :uid => 'a',
        :method => 'b',
        :mime_type => 'image/gif',
        :options => {:a => 'b'},
        :encoding => {:c => 'd'}
      }
      parameters = Imagetastic::Parameters.new(attributes)
      parameters.to_hash.should == attributes
    end
  end
  
end