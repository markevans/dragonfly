require 'spec_helper'
require 'ostruct'

describe Dragonfly::ImageMagick::Processors::Thumb do

  let (:app) { test_imagemagick_app }
  let (:image) { Dragonfly::Content.new(app, SAMPLES_DIR.join('beach.png')) } # 280x355
  let (:processor) { Dragonfly::ImageMagick::Processors::Thumb.new }

  it "raises an error if an unrecognized string is given" do
    expect{
      processor.call(image, '30x40#ne!')
    }.to raise_error(ArgumentError)
  end

  describe "resizing" do

    it "works with xNN" do
      processor.call(image, 'x30')
      image.should have_width(24)
      image.should have_height(30)
    end

    it "works with NNx" do
      processor.call(image, '30x')
      image.should have_width(30)
      image.should have_height(38)
    end

    it "works with NNxNN" do
      processor.call(image, '30x30')
      image.should have_width(24)
      image.should have_height(30)
    end

    it "works with NNxNN!" do
      processor.call(image, '30x30!')
      image.should have_width(30)
      image.should have_height(30)
    end

    it "works with NNxNN%" do
      processor.call(image, '25x50%')
      image.should have_width(70)
      image.should have_height(178)
    end

    describe "NNxNN>" do

      it "doesn't resize if the image is smaller than specified" do
        processor.call(image, '1000x1000>')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "resizes if the image is larger than specified" do
        processor.call(image, '30x30>')
        image.should have_width(24)
        image.should have_height(30)
      end

    end

    describe "NNxNN<" do

      it "doesn't resize if the image is larger than specified" do
        processor.call(image, '10x10<')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "resizes if the image is smaller than specified" do
        processor.call(image, '400x400<')
        image.should have_width(315)
        image.should have_height(400)
      end

    end

  end

  describe "cropping" do # Difficult to test here other than dimensions

    it "crops" do
      processor.call(image, '10x20+30+30')
      image.should have_width(10)
      image.should have_height(20)
    end

    it "crops with gravity" do
      image2 = image.clone

      processor.call(image, '10x8nw')
      image.should have_width(10)
      image.should have_height(8)

      processor.call(image2, '10x8se')
      image2.should have_width(10)
      image2.should have_height(8)

      image2.should_not equal_image(image)
    end

    it "raises if given both gravity and offset" do
      expect {
        processor.call(image, '100x100+10+10se')
      }.to raise_error(ArgumentError)
    end

    it "works when the crop area is outside the image" do
      processor.call(image, '100x100+250+300')
      image.should have_width(30)
      image.should have_height(55)
    end

    it "crops twice in a row correctly" do
      processor.call(image, '100x100+10+10')
      processor.call(image, '50x50+0+0')
      image.should have_width(50)
      image.should have_height(50)
    end

  end

  describe "resize_and_crop" do

    it "crops to the correct dimensions" do
      processor.call(image, '100x100#')
      image.should have_width(100)
      image.should have_height(100)
    end

    it "resizes before cropping" do
      image2 = image.clone
      processor.call(image, '100x100#')
      processor.call(image2, '100x100c')
      image2.should_not equal_image(image)
    end

    it "works with gravity" do
      image2 = image.clone
      processor.call(image, '10x10#nw')
      processor.call(image, '10x10#se')
      image2.should_not equal_image(image)
    end

  end

  describe "format" do
    let (:url_attributes) { OpenStruct.new }

    it "changes the format if passed in" do
      processor.call(image, '2x2', 'format' => 'jpeg')
      image.should have_format('jpeg')
    end

    it "doesn't change the format if not passed in" do
      processor.call(image, '2x2')
      image.should have_format('png')
    end

    it "updates the url ext if passed in" do
      processor.update_url(url_attributes, '2x2', 'format' => 'png')
      url_attributes.ext.should == 'png'
    end

    it "doesn't update the url ext if not passed in" do
      processor.update_url(url_attributes, '2x2')
      url_attributes.ext.should be_nil
    end
  end

  describe "args_for_geometry" do
    it "returns the convert arguments used for a given geometry" do
      expect(processor.args_for_geometry('30x40')).to eq('-resize 30x40')
    end
  end

end
