require 'spec_helper'

describe Dragonfly::ImageMagick::Analysers::Identify do

  let(:analyser) { Dragonfly::ImageMagick::Analysers::Identify.new }
  let(:temp_object) { Dragonfly::TempObject.new(SAMPLES_DIR.join('beach.png')) } # 280x355

  describe "call" do
    it "returns a string" do
      analyser.call(temp_object).should =~ /^#{File.expand_path('samples/beach.png')} PNG 280x355/
    end

    it "allows setting args" do
      analyser.call(temp_object, "-format '%m %w %h'").should == "PNG 280 355"
    end
  end

end
