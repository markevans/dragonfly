require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Plain do
  let (:generator) { Dragonfly::ImageMagick::Generators::Plain.new }
  let (:app) { test_imagemagick_app }
  let (:image) { Dragonfly::Content.new(app) }

  describe "of given dimensions" do
    before(:each) do
      generator.call(image, 3, 2)
    end
    it {image.should have_width(3)}
    it {image.should have_height(2)}
    it {image.should have_format('png')}
    it {image.meta.should == {'format' => 'png', 'name' => 'plain.png'}}
  end

  describe "specifying the format" do
    before(:each) do
      generator.call(image, 1, 1, 'format'=> 'gif')
    end
    it {image.should have_format('gif')}
    it {image.meta.should == {'format' => 'gif', 'name' => 'plain.gif'}}
  end

  describe "specifying the colour" do
    it "works with English spelling" do
      generator.call(image, 1, 1, 'colour' => 'red')
    end

    it "works with American spelling" do
      generator.call(image, 1, 1, 'color' => 'red')
    end

    it "blows up with a bad colour" do
      expect {
        generator.call(image, 1, 1, 'colour' => 'lardoin')
      }.to raise_error(Dragonfly::Shell::CommandFailed)
    end
  end

  describe "urls" do
    it "updates the url" do
      url_attributes = Dragonfly::UrlAttributes.new
      generator.update_url(url_attributes, 1, 1, 'format' => 'gif')
      url_attributes.name.should == 'plain.gif'
    end
  end

end
