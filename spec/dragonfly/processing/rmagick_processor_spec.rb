require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Processing::RMagickProcessor do
  
  before(:each) do
    sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
    @image = Dragonfly::TempObject.new(File.new(sample_file))
    @processor = Object.new
    @processor.extend Dragonfly::Processing::RMagickProcessor
  end
  
  describe "#resize" do
    
    it "should work correctly with xNN" do
      image = @processor.resize(@image, :geometry => 'x30')
      image.should have_width(24)
      image.should have_height(30)
    end
    
    it "should work correctly with NNx" do
      image = @processor.resize(@image, :geometry => '30x')
      image.should have_width(30)
      image.should have_height(38)
    end
    
    it "should work correctly with NNxNN" do
      image = @processor.resize(@image, :geometry => '30x30')
      image.should have_width(24)
      image.should have_height(30)
    end
    
    it "should work correctly with NNxNN!" do
      image = @processor.resize(@image, :geometry => '30x30!')
      image.should have_width(30)
      image.should have_height(30)
    end
    
    it "should work correctly with NNxNN%" do
      image = @processor.resize(@image, :geometry => '25x50%')
      image.should have_width(70)
      image.should have_height(178)
    end
    
    describe "NNxNN>" do
      
      it "should not resize if the image is smaller than specified" do
        image = @processor.resize(@image, :geometry => '1000x1000>')
        image.should have_width(280)
        image.should have_height(355)
      end
      
      it "should resize if the image is larger than specified" do
        image = @processor.resize(@image, :geometry => '30x30>')
        image.should have_width(24)
        image.should have_height(30)
      end
      
    end
    
    describe "NNxNN<" do
      
      it "should not resize if the image is larger than specified" do
        image = @processor.resize(@image, :geometry => '10x10<')
        image.should have_width(280)
        image.should have_height(355)
      end
      
      it "should resize if the image is smaller than specified" do
        image = @processor.resize(@image, :geometry => '400x400<')
        image.should have_width(315)
        image.should have_height(400)
      end
      
    end
    
  end
  
  describe "crop" do # Difficult to test here other than dimensions
    
    it "should not crop if no args given" do
      image = @processor.crop(@image)
      image.should have_width(280)
      image.should have_height(355)
    end
    
    it "should crop using the offset given" do
      image = @processor.crop(@image, :x => 7, :y => 12)
      image.should have_width(273)
      image.should have_height(343)
    end
    
    it "should crop using the dimensions given" do
      image = @processor.crop(@image, :width => 10, :height => 20)
      image.should have_width(10)
      image.should have_height(20)
    end
    
    it "should crop in one dimension if given" do
      image = @processor.crop(@image, :width => 10)
      image.should have_width(10)
      image.should have_height(355)
    end
    
    it "should take into account the gravity given" do
      image1 = @processor.crop(@image, :width => 10, :height => 10, :gravity => 'nw')
      image2 = @processor.crop(@image, :width => 10, :height => 10, :gravity => 'se')
      image1.should_not == image2
    end
    
  end
  
end
