unless ENV['IGNORE_RMAGICK']

  require 'spec_helper'
  require 'dragonfly/analysis/shared_analyser_examples'

  describe Dragonfly::Analysis::RMagickAnalyser do
  
    before(:each) do
      image_path = File.dirname(__FILE__) + '/../../../samples/beach.png'
      @image = Dragonfly::TempObject.new(File.new(image_path))
      @analyser = Dragonfly::Analysis::RMagickAnalyser.new
      @analyser.log = Logger.new(LOG_FILE)
    end
  
    describe "when using the filesystem" do
      before(:each) do
        @analyser.use_filesystem = true
      end
      it_should_behave_like "image analyser methods"
    end
  
    describe "when not using the filesystem" do
      before(:each) do
        @analyser.use_filesystem = false
      end
      it_should_behave_like "image analyser methods"
    end
  
  end

end