unless ENV['IGNORE_RMAGICK']

  require 'spec_helper'

  describe Dragonfly::Encoding::RMagickEncoder do
  
    before(:all) do
      sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
      @image = Dragonfly::TempObject.new(File.new(sample_file))
      @encoder = Dragonfly::Encoding::RMagickEncoder.new
    end
  
    describe "#encode" do
    
      it "should encode the image to the correct format" do
        image = @encoder.encode(@image, :gif)
        image.should have_format('gif')
      end
    
      it "should throw :unable_to_handle if the format is not handleable" do
        lambda{
          @encoder.encode(@image, :goofy)
        }.should throw_symbol(:unable_to_handle)
      end
    
      it "should do nothing if the image is already in the correct format" do
        image = @encoder.encode(@image, :png)
        image.should == @image
      end
    
      it "should work when not using the filesystem" do
        @encoder.use_filesystem = false
        image = @encoder.encode(@image, :gif)
        image.should have_format('gif')
      end

    end
  
  end

end