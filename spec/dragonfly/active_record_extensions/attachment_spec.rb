require File.dirname(__FILE__) + '/spec_helper'

describe Dragonfly::ActiveRecordExtensions::Attachment do  

  before(:each) do
    @app = Dragonfly::App[:images]
    @parent_model = mock('model')
    @attachment = Dragonfly::ActiveRecordExtensions::Attachment.new(@app, @parent_model, :preview_image)
  end

  describe "url" do

    it "should use url_for on the url_handler if model_uid is set" do
      @parent_model.should_receive(:preview_image_uid).at_least(:once).and_return('some_uid')
      @app.should_receive(:url_for).with('some_uid', :arg).and_return('some.url')
      @attachment.url(:arg).should == 'some.url'
    end

    it "should return nil if the model_uid is pending" do
      @parent_model.should_receive(:preview_image_uid).at_least(:once).and_return(Dragonfly::ActiveRecordExtensions::PendingUID.new)
      @attachment.url(:arg).should be_nil
      
    end

    it "should return nil if the model_uid is nil" do
      @parent_model.should_receive(:preview_image_uid).and_return(nil)
      @attachment.url(:arg).should be_nil
    end

  end
  
  describe "destroying" do

    before(:each) do
      @attachment.stub!(:previous_uid).and_return 'blah/food'
    end

    it "should call destroy on the app's datastore" do
      @app.datastore.should_receive(:destroy).with('blah/food')
      @attachment.destroy!
    end

    it "should log a warning if the data wasn't found" do
      @app.datastore.should_receive(:destroy).with('blah/food').and_raise(Dragonfly::DataStorage::DataNotFound)
      @app.log.should_receive(:warn)
      @attachment.destroy!
    end

  end

end