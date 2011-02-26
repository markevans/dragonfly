require 'spec_helper'

describe Dragonfly::ImageMagick::Encoder do
  
  before(:all) do
    sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355, 135KB
    @image = Dragonfly::TempObject.new(File.new(sample_file))
    @encoder = Dragonfly::ImageMagick::Encoder.new
  end
  
  describe "#encode" do
    
    it "should encode the image to the correct format" do
      image = @encoder.encode(@image, :gif)
      image.should have_format('gif')
    end
    
    it "should throw :unable_to_handle if the format is not handleable" do
      lambda{
        @encoder.encode(@image, :goofy)
      }.should throw_symbol(:unable_to_handle)
    end
    
    it "should do nothing if the image is already in the correct format" do
      image = @encoder.encode(@image, :png)
      image.should == @image
    end

    it "should allow for extra args" do
      image = @encoder.encode(@image, :jpg, '-quality 1')
      image.should have_format('jpeg')
      image.should have_size('1.45KB')
    end
    
    it "should still work even if the image is already in the correct format and args are given" do
      image = @encoder.encode(@image, :png, '-quality 1')
      image.should_not == @image
    end
  end
  
end
