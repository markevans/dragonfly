require "spec_helper"

describe Dragonfly::ImageMagick::Generators::Plasma do
  let (:generator) { Dragonfly::ImageMagick::Generators::Plasma.new }
  let (:app) { test_imagemagick_app }
  let (:image) { Dragonfly::Content.new(app) }

  describe "call" do
    it "generates a png image" do
      generator.call(image, 5, 3)
      image.should have_width(5)
      image.should have_height(3)
      image.should have_format("png")
      image.meta.should == { "format" => "png", "name" => "plasma.png" }
    end

    it "allows changing the format" do
      generator.call(image, 1, 1, "format" => "jpg")
      image.should have_format("jpeg")
      image.meta.should == { "format" => "jpg", "name" => "plasma.jpg" }
    end
  end

  describe "urls" do
    it "updates the url" do
      url_attributes = Dragonfly::UrlAttributes.new
      generator.update_url(url_attributes, 1, 1, "format" => "jpg")
      url_attributes.name.should == "plasma.jpg"
    end
  end

  describe "param validations" do
    it "validates format" do
      expect {
        generator.call(image, 1, 1, "format" => "png -write bad.png")
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end

    it "validates width" do
      expect {
        generator.call(image, "1 -write bad.png", 1)
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end

    it "validates height" do
      expect {
        generator.call(image, 1, "1 -write bad.png")
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end
  end
end
