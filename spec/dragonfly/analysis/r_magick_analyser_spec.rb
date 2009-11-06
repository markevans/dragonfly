require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Analysis::RMagickAnalyser do
  
  before(:each) do
    image_path = File.dirname(__FILE__) + '/../../../samples/beach.png'
    @beach = Dragonfly::TempObject.new(File.new(image_path))
    @analyser = Dragonfly::Analysis::RMagickAnalyser.new
  end

  it "should return the width" do
    @analyser.width(@beach).should == 280
  end
  
  it "should return the height" do
    @analyser.height(@beach).should == 355
  end
  
  it "should return the mime type" do
    @analyser.mime_type(@beach).should == 'image/png'
  end
  
  it "should return nil if it doesn't know the mime type" do
    @analyser.mime_type(Dragonfly::TempObject.new('asdf')).should be_nil
  end
  
  it "should return the number of colours" do
    @analyser.number_of_colours(@beach).should == 34703
  end
  
  it "should return the depth" do
    @analyser.depth(@beach).should == 8
  end
  
end