require 'spec_helper'

describe Dragonfly::ImageMagick::Analysers::Identify do

  let(:analyser) { Dragonfly::ImageMagick::Analysers::Identify.new }
  let(:image) { Dragonfly::Content.new(test_app, SAMPLES_DIR.join('beach.png')) } # 280x355

  describe "call" do
    it "returns a string" do
      analyser.call(image).should =~ /^#{File.expand_path('samples/beach.png')} PNG 280x355/
    end

    it "allows setting args" do
      analyser.call(image, "-format '%m %w %h'").should == "PNG 280 355\n"
    end
  end

end
