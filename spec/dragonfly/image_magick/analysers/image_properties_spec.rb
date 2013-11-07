require 'spec_helper'

describe Dragonfly::ImageMagick::Analysers::ImageProperties do

  let(:app) { test_imagemagick_app }
  let(:analyser) { Dragonfly::ImageMagick::Analysers::ImageProperties.new }
  let(:content) { Dragonfly::Content.new(app, SAMPLES_DIR.join('beach.png')) } # 280x355

  describe "call" do
    it "returns a hash of properties" do
      analyser.call(content).should == {
        'width' => 280,
        'height' => 355,
        'format' => 'png'
      }
    end
  end

end

