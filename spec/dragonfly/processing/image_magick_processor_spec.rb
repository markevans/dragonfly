require 'spec_helper'
require 'dragonfly/processing/shared_processing_spec'

describe Dragonfly::Processing::ImageMagickProcessor do
  
  before(:each) do
    sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
    @image = Dragonfly::TempObject.new(File.new(sample_file))
    @processor = Dragonfly::Processing::ImageMagickProcessor.new
  end

  it_should_behave_like "processing methods"
end
