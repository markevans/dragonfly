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

    describe "text" do
      before(:each) do
        @text =  Dragonfly::TempObject.new("mmm")
      end

      it "should create a text image, defaulted to png" do
        image = @processor.text(@text, :font_size => 12)
        image.should have_width(20..40) # approximate
        image.should have_height(10..20)
        image.should have_format('png')
      end

      # it "should ignore percent characters used by rmagick"

      describe "padding" do
        before(:each) do
          no_padding_text = @processor.text(@text, :font_size => 12)
          @width = image_properties(no_padding_text)[:width].to_i
          @height = image_properties(no_padding_text)[:height].to_i
        end
        it "1 number shortcut" do
          image = @processor.text(@text, :padding => '10')
          image.should have_width(@width + 20)
          image.should have_height(@height + 20)
        end
        it "2 numbers shortcut" do
          image = @processor.text(@text, :padding => '10 5')
          image.should have_width(@width + 10)
          image.should have_height(@height + 20)
        end
        it "3 numbers shortcut" do
          image = @processor.text(@text, :padding => '10 5 8')
          image.should have_width(@width + 10)
          image.should have_height(@height + 18)
        end
        it "4 numbers shortcut" do
          image = @processor.text(@text, :padding => '1 2 3 4')
          image.should have_width(@width + 6)
          image.should have_height(@height + 4)
        end
        it "should override the general padding declaration with the specific one (e.g. 'padding-left')" do
          image = @processor.text(@text, :padding => '10', 'padding-left' => 9)
          image.should have_width(@width + 19)
          image.should have_height(@height + 20)
        end
        it "should ignore 'px' suffixes" do
          image = @processor.text(@text, :padding => '1px 2px 3px 4px')
          image.should have_width(@width + 6)
          image.should have_height(@height + 4)
        end
        it "bad padding string" do
          lambda{
            @processor.text(@text, :padding => '1 2 3 4 5')
          }.should raise_error(ArgumentError)
        end
      end
    end

  end
  
end

describe Dragonfly::Processing::RMagickProcessor::HashWithCssStyleKeys do
  before(:each) do
    @hash = Dragonfly::Processing::RMagickProcessor::HashWithCssStyleKeys[
      :font_style => 'normal',
      :'font-weight' => 'bold',
      'font_colour' => 'white',
      'font-size' => 23,
      :hello => 'there'
    ]
  end
  describe "accessing using underscore symbol style" do
    it{ @hash[:font_style].should == 'normal' }
    it{ @hash[:font_weight].should == 'bold' }
    it{ @hash[:font_colour].should == 'white' }
    it{ @hash[:font_size].should == 23 }
    it{ @hash[:hello].should == 'there' }
    it{ @hash[:non_existent_key].should be_nil }
  end
end
