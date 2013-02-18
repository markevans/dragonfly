require 'spec_helper'

describe Dragonfly::ImageMagick::Analysers::IdentifyBasic do

  let(:analyser) { Dragonfly::ImageMagick::Analysers::IdentifyBasic.new }
  let(:temp_object) { Dragonfly::TempObject.new(SAMPLES_DIR.join('beach.png')) } # 280x355

  describe "call" do
    it "returns a hash of properties" do
      analyser.call(temp_object).should == {
        'width' => 280,
        'height' => 355,
        'format' => :png
      }
    end
  end

end
