require 'spec_helper'

describe Dragonfly::ImageMagick::Processors::Convert do
  
  before(:each) do
    @image = Dragonfly::TempObject.new(SAMPLES_DIR.join('beach.png')) # 280x355
    @processor = Dragonfly::ImageMagick::Processors::Convert.new
  end

  it "should allow for general convert commands" do
    image, meta = @processor.call(@image, '-scale 56x71')
    image.should have_width(56)
    image.should have_height(71)
  end
  
  it "should allow for general convert commands with added format" do
    image, meta = @processor.call(@image, '-scale 56x71', :gif)
    image.should have_width(56)
    image.should have_height(71)
    image.should have_format('gif')
    meta[:format].should == :gif
  end

  it "should work for commands with parenthesis" do
    image, meta = @processor.call(@image, "\\( +clone -sparse-color Barycentric '0,0 black 0,%[fx:h-1] white' -function polynomial 2,-2,0.5 \\) -compose Blur -set option:compose:args 15 -composite")
    image.should have_width(280)
  end

  it "should work for files with spaces in the name" do
    image = Dragonfly::TempObject.new(SAMPLES_DIR.join('white pixel.png'))
    image, meta = @processor.call(image, "-resize 2x2!")
    image.should have_width(2)
  end

end
