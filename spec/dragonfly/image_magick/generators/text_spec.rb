require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Text do
  let (:generator) { Dragonfly::ImageMagick::Generators::Text.new }
  let (:app) { test_imagemagick_app }
  let (:image) { Dragonfly::Content.new(app) }

  describe "creating a text image" do
    before(:each) do
      generator.call(image, "mmm", 'font_size' => 12)
    end
    it {image.should have_width(20..40)} # approximate
    it {image.should have_height(10..20)}
    it {image.should have_format('png')}
    it {image.meta.should == {'format' => 'png', 'name' => 'text.png'}}
  end

  describe "specifying the format" do
    before(:each) do
      generator.call(image, "mmm", 'format' => 'gif')
    end
    it {image.should have_format('gif')}
    it {image.meta.should == {'format' => 'gif', 'name' => 'text.gif'}}
  end

  describe "padding" do
    before(:each) do
      image_without_padding = image.clone
      generator.call(image_without_padding, "mmm", 'font_size' => 12)
      @width = image_properties(image_without_padding)[:width].to_i
      @height = image_properties(image_without_padding)[:height].to_i
    end
    it "1 number shortcut" do
      generator.call(image, "mmm", 'padding' => '10')
      image.should have_width(@width + 20)
      image.should have_height(@height + 20)
    end
    it "2 numbers shortcut" do
      generator.call(image, "mmm", 'padding' => '10 5')
      image.should have_width(@width + 10)
      image.should have_height(@height + 20)
    end
    it "3 numbers shortcut" do
      generator.call(image, "mmm", 'padding' => '10 5 8')
      image.should have_width(@width + 10)
      image.should have_height(@height + 18)
    end
    it "4 numbers shortcut" do
      generator.call(image, "mmm", 'padding' => '1 2 3 4')
      image.should have_width(@width + 6)
      image.should have_height(@height + 4)
    end
    it "should override the general padding declaration with the specific one (e.g. 'padding-left')" do
      generator.call(image, "mmm", 'padding' => '10', 'padding-left' => 9)
      image.should have_width(@width + 19)
      image.should have_height(@height + 20)
    end
    it "should ignore 'px' suffixes" do
      generator.call(image, "mmm", 'padding' => '1px 2px 3px 4px')
      image.should have_width(@width + 6)
      image.should have_height(@height + 4)
    end
    it "bad padding string" do
      lambda{
        generator.call(image, "mmm", 'padding' => '1 2 3 4 5')
      }.should raise_error(ArgumentError)
    end
  end

  describe "urls" do
    it "updates the url" do
      url_attributes = Dragonfly::UrlAttributes.new
      generator.update_url(url_attributes, "mmm", 'format' => 'gif')
      url_attributes.name.should == 'text.gif'
    end
  end
end
