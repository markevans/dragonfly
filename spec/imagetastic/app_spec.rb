require File.dirname(__FILE__) + '/../spec_helper'
require 'rack/mock'

describe Imagetastic::App do

  before(:each) do
    @app = Imagetastic::App.new
    @request = Rack::MockRequest.new(@app)
  end
  
  describe "#get_processed_object" do
    
    before(:each) do
      @temp_object = mock('temp_object', :data => 'AAA', :file => mock('file'))
      @params = Imagetastic::Parameters.new(
        :uid => 'ahaha',
        :processing_method => :resize,
        :processing_options => {:scale => 0.5},
        :mime_type => 'image/jpeg',
        :encoding => {:bitrate => 256}
      )
      @app.datastore.stub!(:retrieve)
      @app.processor.stub!(:process)
      @app.encoder.stub!(:encode)
    end
    
    it "should validate params, retreive, process and encode an object" do
      @params.should_receive(:validate!)
      @app.datastore.should_receive(:retrieve).with('ahaha').and_return(@temp_object)
      @app.processor.should_receive(:process).with(@temp_object, :resize, {:scale => 0.5}).and_return(@temp_object)
      @app.encoder.should_receive(:encode).with(@temp_object, 'image/jpeg', {:bitrate => 256}).and_return(@temp_object)
      @app.get_processed_object(@params)
    end
    
    it "should not call the processor if no processing method is given" do
      @params.processing_method = nil
      @app.processor.should_not_receive(:process)
      @app.get_processed_object(@params)
    end
    
    it "should not call the encoder if no mime type is given" do
      @params.mime_type = nil
      @app.encoder.should_not_receive(:encode)
      @app.get_processed_object(@params)
    end
    
  end

end