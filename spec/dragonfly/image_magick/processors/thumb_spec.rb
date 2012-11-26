require 'spec_helper'

describe Dragonfly::ImageMagick::Processors::Thumb do
  
  before(:each) do
    @image = Dragonfly::TempObject.new(SAMPLES_DIR.join('beach.png')) # 280x355
    @processor = Dragonfly::ImageMagick::Processors::Thumb.new
  end

  describe "resize" do

    it "should work correctly with xNN" do
      image = @processor.resize(@image, 'x30')
      image.should have_width(24)
      image.should have_height(30)
    end

    it "should work correctly with NNx" do
      image = @processor.resize(@image, '30x')
      image.should have_width(30)
      image.should have_height(38)
    end

    it "should work correctly with NNxNN" do
      image = @processor.resize(@image, '30x30')
      image.should have_width(24)
      image.should have_height(30)
    end

    it "should work correctly with NNxNN!" do
      image = @processor.resize(@image, '30x30!')
      image.should have_width(30)
      image.should have_height(30)
    end

    it "should work correctly with NNxNN%" do
      image = @processor.resize(@image, '25x50%')
      image.should have_width(70)
      image.should have_height(178)
    end

    describe "NNxNN>" do

      it "should not resize if the image is smaller than specified" do
        image = @processor.resize(@image, '1000x1000>')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "should resize if the image is larger than specified" do
        image = @processor.resize(@image, '30x30>')
        image.should have_width(24)
        image.should have_height(30)
      end

    end

    describe "NNxNN<" do

      it "should not resize if the image is larger than specified" do
        image = @processor.resize(@image, '10x10<')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "should resize if the image is smaller than specified" do
        image = @processor.resize(@image, '400x400<')
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
      image1.should_not equal_image(image2)
    end

    it "should clip bits of the image outside of the requested crop area when not nw gravity" do
      # Rmagick was previously throwing an error when the cropping area was outside the image size, when
      # using a gravity other than nw
      image = @processor.crop(@image, :width => '500', :height => '1000', :x => '100', :y => '200', :gravity => 'se')
      image.should have_width(180)
      image.should have_height(155)
    end
    
    it "should crop twice in a row correctly" do
      image1 = @processor.crop(@image,  :x => '10', :y => '10', :width => '100', :height => '100')
      image2 = @processor.crop(Dragonfly::TempObject.new(image1), :x => '0' , :y => '0' , :width => '50' , :height => '50' )
      image2.should have_width(50)
      image2.should have_height(50)
    end

  end

  describe "resize_and_crop" do

    it "should do nothing if no args given" do
      image = @processor.resize_and_crop(@image)
      image.should have_width(280)
      image.should have_height(355)
    end

    it "should do nothing if called without width and height" do
      image = @processor.resize_and_crop(@image)
      image.should have_width(280)
      image.should have_height(355)
      image.should eq @image
    end

    it "should crop to the correct dimensions" do
      image = @processor.resize_and_crop(@image, :width => '100', :height => '100')
      image.should have_width(100)
      image.should have_height(100)
    end

    it "should actually resize before cropping" do
      image1 = @processor.resize_and_crop(@image, :width => '100', :height => '100')
      image2 = @processor.crop(@image, :width => '100', :height => '100', :gravity => 'c')
      image1.should_not equal_image(image2)
    end

    it "should allow cropping in one dimension" do
      image = @processor.resize_and_crop(@image, :width => '100')
      image.should have_width(100)
      image.should have_height(355)
    end

    it "should take into account the gravity given" do
      image1 = @processor.resize_and_crop(@image, :width => '10', :height => '10', :gravity => 'nw')
      image2 = @processor.resize_and_crop(@image, :width => '10', :height => '10', :gravity => 'se')
      image1.should_not equal_image(image2)
    end

  end

  describe "call" do
    it "should call resize if the correct string given" do
      @processor.should_receive(:resize).with(@image, '30x40').and_return(image = mock)
      @processor.call(@image, '30x40').should == image
    end
    it "should call resize_and_crop if the correct string given" do
      @processor.should_receive(:resize_and_crop).with(@image, :width => '30', :height => '40', :gravity => 'se').and_return(image = mock)
      @processor.call(@image, '30x40#se').should == image
    end
    it "should call crop if x and y given" do
      @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => '+10', :y => '+20', :gravity => nil).and_return(image = mock)
      @processor.call(@image, '30x40+10+20').should == image
    end
    it "should call crop if just gravity given" do
      @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => nil, :y => nil, :gravity => 'sw').and_return(image = mock)
      @processor.call(@image, '30x40sw').should == image
    end
    it "should call crop if x, y and gravity given" do
      @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => '-10', :y => '-20', :gravity => 'se').and_return(image = mock)
      @processor.call(@image, '30x40-10-20se').should == image
    end
    it "should raise an argument error if an unrecognized string is given" do
      lambda{ @processor.call(@image, '30x40#ne!') }.should raise_error(ArgumentError)
    end
  end

end
