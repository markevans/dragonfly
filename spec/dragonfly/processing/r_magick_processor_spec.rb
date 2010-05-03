require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Processing::RMagickProcessor do
  
  describe "generate" do
    before(:each) do
      @processor = Dragonfly::Processing::RMagickProcessor.new
    end
    
    it "should generate an image with the given dimensions, defaulting to png format" do
      image = @processor.generate(23,12)
      image.should have_width(23)
      image.should have_height(12)
      image.should have_format('png')
    end
    it "should allow specifying the format" do
      image = @processor.generate(23, 12, :gif)
      image.should have_format('gif')
    end
  end

  describe "processing methods" do
  
    before(:each) do
      sample_file = File.dirname(__FILE__) + '/../../../samples/beach.png' # 280x355
      @image = Dragonfly::TempObject.new(File.new(sample_file))
      @processor = Dragonfly::Processing::RMagickProcessor.new
    end
  
    describe "resize" do
    
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
        image = @processor.crop(@image, :x => '7', :y => '12')
        image.should have_width(273)
        image.should have_height(343)
      end
    
      it "should crop using the dimensions given" do
        image = @processor.crop(@image, :width => '10', :height => '20')
        image.should have_width(10)
        image.should have_height(20)
      end
    
      it "should crop in one dimension if given" do
        image = @processor.crop(@image, :width => '10')
        image.should have_width(10)
        image.should have_height(355)
      end
    
      it "should take into account the gravity given" do
        image1 = @processor.crop(@image, :width => '10', :height => '10', :gravity => 'nw')
        image2 = @processor.crop(@image, :width => '10', :height => '10', :gravity => 'se')
        image1.should_not == image2
      end
    
      it "should clip bits of the image outside of the requested crop area when not nw gravity" do
        # Rmagick was previously throwing an error when the cropping area was outside the image size, when
        # using a gravity other than nw
        image = @processor.crop(@image, :width => '500', :height => '1000', :x => '100', :y => '200', :gravity => 'se')
        image.should have_width(180)
        image.should have_height(155)
      end
    
    end

    describe "greyscale" do
      it "should not raise an error" do
        # Bit tricky to test
        @processor.greyscale(@image)
      end
    end

    describe "resize_and_crop" do
    
      it "should do nothing if no args given" do
        image = @processor.resize_and_crop(@image)
        image.should have_width(280)
        image.should have_height(355)
      end
    
      it "should crop to the correct dimensions" do
        image = @processor.resize_and_crop(@image, :width => '100', :height => '100')
        image.should have_width(100)
        image.should have_height(100)
      end
    
      it "should allow cropping in one dimension" do
        image = @processor.resize_and_crop(@image, :width => '100')
        image.should have_width(100)
        image.should have_height(355)
      end
    
      it "should take into account the gravity given" do
        image1 = @processor.resize_and_crop(@image, :width => '10', :height => '10', :gravity => 'nw')
        image2 = @processor.resize_and_crop(@image, :width => '10', :height => '10', :gravity => 'se')
        image1.should_not == image2
      end
    
    end
  
    describe "rotate" do
    
      it "should rotate by 90 degrees" do
        image = @processor.rotate(@image, :amount => '90')
        image.should have_width(355)
        image.should have_height(280)
      end
    
      it "should not rotate given a larger height and the '>' qualifier" do
        image = @processor.rotate(@image, :amount => 90, :qualifier => '>')
        image.should have_width(280)
        image.should have_height(355)
      end
    
      it "should rotate given a larger height and the '<' qualifier" do
        image = @processor.rotate(@image, :amount => 90, :qualifier => '<')
        image.should have_width(355)
        image.should have_height(280)
      end
    
      it "should do nothing if no amount given" do
        image = @processor.rotate(@image)
        image.should have_width(280)
        image.should have_height(355)
      end
    
    end
  end
  
end
