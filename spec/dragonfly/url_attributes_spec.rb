require 'spec_helper'

describe Dragonfly::UrlAttributes do

  let(:url_attrs) { Dragonfly::UrlAttributes.new }

  describe "empty" do
    it "returns true when empty" do
      url_attrs.empty?.should be_true
    end

    it "returns false when not empty" do
      url_attrs.some = 'thing'
      url_attrs.empty?.should be_false
    end

    it "returns true if all values are nil" do
      url_attrs.some = nil
      url_attrs.empty?.should be_true
    end
  end

  describe "format" do
    # because 'format' is already private on kernel, using 'send' calls it so we need a workaround
    it "acts like other openstruct attributes when using 'send'" do
      url_attrs.send(:format).should be_nil
      url_attrs.format = "clive"
      url_attrs.send(:format).should == "clive"
      url_attrs.should_not be_empty
    end
  end

end
