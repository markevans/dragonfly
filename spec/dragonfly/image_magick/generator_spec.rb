require 'spec_helper'

describe Dragonfly::ImageMagick::Generator do

  before(:each) do
    @generator = Dragonfly::ImageMagick::Generator.new
  end

  describe "plain" do
    describe "of given dimensions and colour" do
      before(:each) do
        @image, @meta = @generator.plain(23,12,'white')
      end
      it {@image.should have_width(23)}
      it {@image.should have_height(12)}
      it {@image.should have_format('png')}
      it {@meta.should == {:format => :png, :name => 'plain.png'}}
    end
    
    it "should cope with colour name format" do
      image, meta = @generator.plain(1, 1, 'red')
      image.should have_width(1)
    end

    it "should cope with rgb format" do
      image, meta = @generator.plain(1, 1, 'rgb(244,255,1)')
      image.should have_width(1)
    end

    it "should cope with rgb percent format" do
      image, meta = @generator.plain(1, 1, 'rgb(100%,50%,20%)')
      image.should have_width(1)
    end

    it "should cope with hex format" do
      image, meta = @generator.plain(1, 1, '#fdafda')
      image.should have_width(1)
    end

    it "should cope with uppercase hex format" do
      image, meta = @generator.plain(1, 1, '#FDAFDA')
      image.should have_width(1)
    end

    it "should cope with shortened hex format" do
      image, meta = @generator.plain(1, 1, '#fda')
      image.should have_width(1)
    end

    it "should cope with 'transparent'" do
      image, meta = @generator.plain(1, 1, 'transparent')
      image.should have_width(1)
    end

    it "should cope with rgba format" do
      image, meta = @generator.plain(1, 1, 'rgba(25,100,255,0.5)')
      image.should have_width(1)
    end

    it "should cope with hsl format" do
      image, meta = @generator.plain(1, 1, 'hsl(25,100,255)')
      image.should have_width(1)
    end

    it "should blow up with an invalid colour" do
      lambda{
        @generator.plain(1,1,'rgb(doogie)')
      }.should_not raise_error()
    end

    describe "specifying the format" do
      before(:each) do
        @image, @meta = @generator.plain(23, 12, 'white', :format => :gif)
      end
      it {@image.should have_format('gif')}
      it {@meta.should == {:format => :gif, :name => 'plain.gif'}}
    end
  end

  describe "plasma" do
    describe "of given dimensions" do
      before(:each) do
        @image, @meta = @generator.plasma(23,12)
      end
      it {@image.should have_width(23)}
      it {@image.should have_height(12)}
      it {@image.should have_format('png')}
      it {@meta.should == {:format => :png, :name => 'plasma.png'}}
    end

    describe "specifying the format" do
      before(:each) do
        @image, @meta = @generator.plasma(23, 12, :gif)
      end
      it {@image.should have_format('gif')}
      it {@meta.should == {:format => :gif, :name => 'plasma.gif'}}
    end
  end

  describe "text" do
    before(:each) do
      @text = "mmm"
    end

    describe "creating a text image" do
      before(:each) do
        @image, @meta = @generator.text(@text, :font_size => 12)
      end
      it {@image.should have_width(20..40)} # approximate
      it {@image.should have_height(10..20)}
      it {@image.should have_format('png')}
      it {@meta.should == {:format => :png, :name => 'text.png'}}
    end

    describe "specifying the format" do
      before(:each) do
        @image, @meta = @generator.text(@text, :format => :gif)
      end
      it {@image.should have_format('gif')}
      it {@meta.should == {:format => :gif, :name => 'text.gif'}}
    end

    describe "padding" do
      before(:each) do
        no_padding_text, meta = @generator.text(@text, :font_size => 12)
        @width = image_properties(no_padding_text)[:width].to_i
        @height = image_properties(no_padding_text)[:height].to_i
      end
      it "1 number shortcut" do
        image, meta = @generator.text(@text, :padding => '10')
        image.should have_width(@width + 20)
        image.should have_height(@height + 20)
      end
      it "2 numbers shortcut" do
        image, meta = @generator.text(@text, :padding => '10 5')
        image.should have_width(@width + 10)
        image.should have_height(@height + 20)
      end
      it "3 numbers shortcut" do
        image, meta = @generator.text(@text, :padding => '10 5 8')
        image.should have_width(@width + 10)
        image.should have_height(@height + 18)
      end
      it "4 numbers shortcut" do
        image, meta = @generator.text(@text, :padding => '1 2 3 4')
        image.should have_width(@width + 6)
        image.should have_height(@height + 4)
      end
      it "should override the general padding declaration with the specific one (e.g. 'padding-left')" do
        image, meta = @generator.text(@text, :padding => '10', 'padding-left' => 9)
        image.should have_width(@width + 19)
        image.should have_height(@height + 20)
      end
      it "should ignore 'px' suffixes" do
        image, meta = @generator.text(@text, :padding => '1px 2px 3px 4px')
        image.should have_width(@width + 6)
        image.should have_height(@height + 4)
      end
      it "bad padding string" do
        lambda{
          @generator.text(@text, :padding => '1 2 3 4 5')
        }.should raise_error(ArgumentError)
      end
    end
  end

end
