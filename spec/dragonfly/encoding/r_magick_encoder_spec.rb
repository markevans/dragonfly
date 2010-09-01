require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Encoding::RMagickEncoder do
  
  before(:all) do
    sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
    @image = Dragonfly::TempObject.new(File.new(sample_file))
    @encoder = Dragonfly::Encoding::RMagickEncoder.new
  end
  
  describe "#encode" do
    
    it "should encode the image to the correct format" do
      image = @encoder.encode(@image, :gif)
      image.should have_format('gif')
    end
    
    it "should throw :unable_to_handle if the format is not handleable" do
      test_string = "I'm a string"
      catch :unable_to_handle do
        @encoder.encode(@image, :goofy)
        test_string = "This line should not happen"
      end
      test_string.should == "I'm a string"
    end
    
    it "should do nothing if the image is already in the correct format" do
      image = @encoder.encode(@image, :png)
      image.should == @image
    end
    
    it "should work when not using the filesystem" do
      @encoder.use_filesystem = false
      image = @encoder.encode(@image, :gif)
      image.should have_format('gif')
    end

  end
  
end