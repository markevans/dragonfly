require 'spec_helper'
require 'dragonfly/processing/shared_processing_spec'

describe Dragonfly::Processing::ImageMagickProcessor do
  
  before(:each) do
    sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
    @image = Dragonfly::TempObject.new(File.new(sample_file))
    @processor = Dragonfly::Processing::ImageMagickProcessor.new
  end

  it_should_behave_like "processing methods"
  
  describe "convert" do
    it "should allow for general convert commands" do
      image = @processor.convert(@image, '-scale 56x71')
      image.should have_width(56)
      image.should have_height(71)
    end
    it "should allow for general convert commands with added format" do
      image, extra = @processor.convert(@image, '-scale 56x71', :gif)
      image.should have_width(56)
      image.should have_height(71)
      image.should have_format('gif')
      extra[:format].should == :gif
    end
  end
  
end
