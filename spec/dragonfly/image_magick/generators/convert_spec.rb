require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Convert do
  let (:generator) { Dragonfly::ImageMagick::Generators::Convert.new }
  let (:app) { test_app }
  let (:image) { Dragonfly::Content.new(app) }

  describe "calling convert" do
    before(:each) do
      generator.call(image, "-size 1x1 xc:white", 'png')
    end
    it {image.should have_width(1)}
    it {image.should have_height(1)}
    it {image.should have_format('png')}
    it {image.meta.should == {'format' => 'png'}}
  end

end

