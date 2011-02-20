require 'spec_helper'
require 'dragonfly/analysis/shared_analyser_examples'

describe Dragonfly::Analysis::ImageMagickAnalyser do
  
  before(:each) do
    image_path = File.dirname(__FILE__) + '/../../../samples/beach.png'
    @image = Dragonfly::TempObject.new(File.new(image_path))
    @analyser = Dragonfly::Analysis::ImageMagickAnalyser.new
  end

  it_should_behave_like "image analyser methods"

end
