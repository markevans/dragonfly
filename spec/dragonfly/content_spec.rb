require 'spec_helper'

describe Dragonfly::Content do

  let(:app) { test_app }

  let(:content) { Dragonfly::Content.new(app) }

  describe "temp_object" do
    it "starts as nil" do
      content.temp_object.should == nil
    end
  end

  describe "meta" do
    it "defaults to an empty hash" do
      content.meta.should == {}
    end
  end

  describe "name" do
    it "defaults to nil" do
      content.name.should be_nil
    end

    it "gets taken from the meta" do
      content.meta[:name] = 'some.name'
      content.name.should == 'some.name'
    end

    it "has basename/name/ext setters" do
      content.name = 'hello.there'
      content.name.should == 'hello.there'
      content.basename.should == 'hello'
      content.ext.should == 'there'
      content.ext = 'schmo'
      content.name.should == 'hello.schmo'
    end

    it "falls back to the temp_object original_filename" do
      content.should_receive(:temp_object).at_least(:once).and_return(mock('temp_object', :original_filename => 'something.original'))
      content.name.should == "something.original"
      content.basename.should == 'something'
      content.ext.should == 'original'
    end
  end

  describe "process!" do
    it "calls the app's processor on itself" do
      content.processor.should_receive(:process).with(:shizzle, content, 'args')
      content.process!(:shizzle, 'args')
    end
  end

  describe "analyse" do
  end

  describe "update" do

  end
end
