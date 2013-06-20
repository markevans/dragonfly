require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Plasma do
  let (:generator) { Dragonfly::ImageMagick::Generators::Plasma.new }
  let (:app) { test_imagemagick_app }
  let (:image) { Dragonfly::Content.new(app) }

  it "generates a png image" do
    generator.call(image, 5, 3)
    image.should have_width(5)
    image.should have_height(3)
    image.should have_format('png')
    image.meta.should == {'format' => 'png', 'name' => 'plasma.png'}
  end

  it "allows changing the format" do
    generator.call(image, 1, 1, 'format' => 'jpg')
    image.should have_format('jpeg')
    image.meta.should == {'format' => 'jpg', 'name' => 'plasma.jpg'}
  end
end

