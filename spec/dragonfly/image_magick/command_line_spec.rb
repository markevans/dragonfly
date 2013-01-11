require 'spec_helper'
require 'pathname'

describe Dragonfly::ImageMagick::CommandLine do

  let(:command_line){ Dragonfly::ImageMagick::CommandLine.new }
  let(:temp_object){ Dragonfly::TempObject.new(Pathname.new('samples/beach.png')) } # 280x355

  describe "convert" do
    it "converts and returns a tempfile" do
      tempfile = command_line.convert(temp_object, '-resize 10x')
      tempfile.should be_a(Tempfile)
      tempfile.should have_width(10)
    end
  end

  describe "identify" do
    it "identifies a temp_object" do
      command_line.identify(temp_object).should =~ /^#{File.expand_path('samples/beach.png')} PNG 280x355/
    end

    it "allows setting args" do
      command_line.identify(temp_object, "-format '%m %w %h'").should == "PNG 280 355"
    end
  end

end
