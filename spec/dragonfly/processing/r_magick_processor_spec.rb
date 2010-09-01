require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Processing::RMagickProcessor do
  
  describe "processing methods", :shared => true do

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
        image = @processor.rotate(@image, 90)
        image.should have_width(355)
        image.should have_height(280)
      end

      it "should not rotate given a larger height and the '>' qualifier" do
        image = @processor.rotate(@image, 90, :qualifier => '>')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "should rotate given a larger height and the '<' qualifier" do
        image = @processor.rotate(@image, 90, :qualifier => '<')
        image.should have_width(355)
        image.should have_height(280)
      end

    end

    describe "thumb" do
      it "should call resize if the correct string given" do
        @processor.should_receive(:resize).with(@image, '30x40').and_return(image = mock)
        @processor.thumb(@image, '30x40').should == image
      end
      it "should call resize_and_crop if the correct string given" do
        @processor.should_receive(:resize_and_crop).with(@image, :width => '30', :height => '40', :gravity => 'se').and_return(image = mock)
        @processor.thumb(@image, '30x40#se').should == image
      end
      it "should call crop if x and y given" do
        @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => '+10', :y => '+20', :gravity => nil).and_return(image = mock)
        @processor.thumb(@image, '30x40+10+20').should == image
      end
      it "should call crop if just gravity given" do
        @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => nil, :y => nil, :gravity => 'sw').and_return(image = mock)
        @processor.thumb(@image, '30x40sw').should == image
      end
      it "should call crop if x, y and gravity given" do
        @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => '-10', :y => '-20', :gravity => 'se').and_return(image = mock)
        @processor.thumb(@image, '30x40-10-20se').should == image
      end
      it "should raise an argument error if an unrecognized string is given" do
        lambda{ @processor.thumb(@image, '30x40#ne!') }.should raise_error(ArgumentError)
      end
    end

    describe "flip" do
      it "should flip the image, leaving the same dimensions" do
        image = @processor.flip(@image)
        image.should have_width(280)
        image.should have_height(355)
      end
    end

    describe "flop" do
      it "should flop the image, leaving the same dimensions" do
        image = @processor.flop(@image)
        image.should have_width(280)
        image.should have_height(355)
      end
    end

  end

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
