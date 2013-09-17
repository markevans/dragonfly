require 'spec_helper'

describe Dragonfly::ImageMagick::Processors::Convert do

  let(:app){ test_app }
  let(:image){ Dragonfly::Content.new(app, SAMPLES_DIR.join('beach.png')) } # 280x355
  let(:processor){ Dragonfly::ImageMagick::Processors::Convert.new }

  it "should allow for general convert commands" do
    processor.call(image, '-scale 56x71')
    image.should have_width(56)
    image.should have_height(71)
  end

  it "should allow for general convert commands with added format" do
    processor.call(image, '-scale 56x71', 'format' => 'gif')
    image.should have_width(56)
    image.should have_height(71)
    image.should have_format('gif')
    image.meta['format'].should == 'gif'
  end

  it "should work for commands with parenthesis" do
    processor.call(image, "\\( +clone -sparse-color Barycentric '0,0 black 0,%[fx:h-1] white' -function polynomial 2,-2,0.5 \\) -compose Blur -set option:compose:args 15 -composite")
    image.should have_width(280)
  end

  it "should work for files with spaces in the name" do
    image = Dragonfly::Content.new(app, SAMPLES_DIR.join('white pixel.png'))
    processor.call(image, "-resize 2x2!")
    image.should have_width(2)
  end

  it "updates the url with format if given" do
    url_attrs = Dragonfly::UrlAttributes.new
    processor.update_url(url_attrs, '-scale 56x71', 'format' => 'gif')
    url_attrs.ext.should == 'gif'
  end

end
