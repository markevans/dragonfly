require "spec_helper"

describe Dragonfly::ImageMagick::Processors::Encode do
  let (:app) { test_imagemagick_app }
  let (:image) { Dragonfly::Content.new(app, SAMPLES_DIR.join("beach.png")) } # 280x355
  let (:processor) { Dragonfly::ImageMagick::Processors::Encode.new }

  it "encodes to a different format" do
    processor.call(image, "jpeg")
    image.should have_format("jpeg")
  end

  describe "param validations" do
    it "validates the format param" do
      expect {
        processor.call(image, "jpeg -write bad.png")
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end

    it "allows good args" do
      processor.call(image, "jpeg", "-quality 10")
    end

    it "disallows bad args" do
      expect {
        processor.call(image, "jpeg", "-write bad.png")
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end
  end
end
