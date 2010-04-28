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
  
  it "should return the aspect ratio" do
    @analyser.aspect_ratio(@beach).should == (280.0/355.0)
  end
  
  it "should return the number of colours" do
    @analyser.number_of_colours(@beach).should == 34703
  end
  
  it "should return the depth" do
    @analyser.depth(@beach).should == 8
  end
  
  it "should return the format" do
    @analyser.format(@beach).should == :png
  end
  
  %w(width height aspect_ratio number_of_colours depth format).each do |meth|
    it "should throw unable_to_handle in #{meth.inspect} if it's not an image file" do
      temp_object = Dragonfly::TempObject.new('blah')
      lambda{
        @analyser.send(meth, temp_object)
      }.should throw_symbol(:unable_to_handle)
    end
  end
  
end
