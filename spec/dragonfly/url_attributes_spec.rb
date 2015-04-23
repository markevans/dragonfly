require 'spec_helper'

describe Dragonfly::UrlAttributes do

  let(:url_attributes) { Dragonfly::UrlAttributes.new }

  describe "empty" do
    it "returns true when empty" do
      url_attributes.empty?.should be_truthy
    end

    it "returns false when not empty" do
      url_attributes.some = 'thing'
      url_attributes.empty?.should be_falsey
    end

    it "returns true if all values are nil" do
      url_attributes.some = nil
      url_attributes.empty?.should be_truthy
    end
  end

  describe "format" do
    # because 'format' is already private on kernel, using 'send' calls it so we need a workaround
    it "acts like other openstruct attributes when using 'send'" do
      url_attributes.send(:format).should be_nil
      url_attributes.format = "clive"
      url_attributes.send(:format).should == "clive"
      url_attributes.should_not be_empty
    end
  end

  describe "extract" do
    it "returns a hash for the given keys" do
      url_attributes.egg = 'boiled'
      url_attributes.veg = 'beef'
      url_attributes.lard = 'lean'
      url_attributes.extract(['egg', 'veg']).should == {'egg' => 'boiled', 'veg' => 'beef'}
    end

    it "excludes blank values" do
      url_attributes.egg = ''
      url_attributes.veg = nil
      url_attributes.extract(['egg', 'veg']).should == {}
    end
  end

end

