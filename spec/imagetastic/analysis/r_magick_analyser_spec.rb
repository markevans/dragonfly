require File.dirname(__FILE__) + '/../../spec_helper'

describe Imagetastic::Analysis::RMagickAnalyser do
  
  before(:each) do
    image_path = File.dirname(__FILE__) + '/../../../samples/beach.png'
    @beach = Imagetastic::TempObject.new(File.new(image_path))
    @beach.extend(Imagetastic::Analysis::RMagickAnalyser)
  end

  it "should return the width" do
    @beach.width.should == 280
  end
  
  it "should return the height" do
    @beach.height.should == 355
  end
  
  it "should return the mime type" do
    @beach.mime_type.should == 'image/png'
  end
  
  it "should return the number of colours" do
    @beach.number_of_colours.should == 34703
  end
  
  it "should return the depth" do
    @beach.depth.should == 8
  end
  
end