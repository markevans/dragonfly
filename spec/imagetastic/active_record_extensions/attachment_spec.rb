require File.dirname(__FILE__) + '/spec_helper'

describe Imagetastic::ActiveRecordExtensions::Attachment do  

  describe "url" do

    before(:each) do
      @app = Imagetastic::App[:images]
      @parent_model = mock('model')
      @attachment = Imagetastic::ActiveRecordExtensions::Attachment.new(@app, @parent_model, :preview_image)
    end

    it "should use url_for on the url_handler if model_uid is set" do
      @parent_model.should_receive(:preview_image_uid).at_least(:once).and_return('some_uid')
      @app.should_receive(:url_for).with('some_uid', :arg).and_return('some.url')
      @attachment.url(:arg).should == 'some.url'
    end

    it "should return nil if the model_uid is pending" do
      @parent_model.should_receive(:preview_image_uid).at_least(:once).and_return(Imagetastic::ActiveRecordExtensions::PendingUID.new)
      @attachment.url(:arg).should be_nil
      
    end

    it "should return nil if the model_uid is nil" do
      @parent_model.should_receive(:preview_image_uid).and_return(nil)
      @attachment.url(:arg).should be_nil
    end

  end

end