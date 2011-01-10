unless ENV['IGNORE_RMAGICK']

  require 'spec_helper'
  require 'dragonfly/processing/shared_processing_spec'

  describe Dragonfly::Processing::RMagickProcessor do
  
    before(:each) do
      sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
      @image = Dragonfly::TempObject.new(File.new(sample_file))
      @processor = Dragonfly::Processing::RMagickProcessor.new
    end

    describe "when using the filesystem" do
      before(:each) do
        @processor.use_filesystem = true
      end
      it_should_behave_like "processing methods"
    end

    describe "when not using the filesystem" do
      before(:each) do
        @processor.use_filesystem = false
      end
      it_should_behave_like "processing methods"
    end

  end
  
end
