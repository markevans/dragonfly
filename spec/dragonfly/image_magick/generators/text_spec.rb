require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Text do
  before(:each) do
    @generator = Dragonfly::ImageMagick::Generators::Text.new
    @text = "mmm"
  end

  describe "creating a text image" do
    before(:each) do
      @image, @meta = @generator.call(@text, :font_size => 12)
    end
    it {@image.should have_width(20..40)} # approximate
    it {@image.should have_height(10..20)}
    it {@image.should have_format('png')}
    it {@meta.should == {:format => :png, :name => 'text.png'}}
  end

  describe "specifying the format" do
    before(:each) do
      @image, @meta = @generator.call(@text, :format => :gif)
    end
    it {@image.should have_format('gif')}
    it {@meta.should == {:format => :gif, :name => 'text.gif'}}
  end

  describe "padding" do
    before(:each) do
      no_padding_text, meta = @generator.call(@text, :font_size => 12)
      @width = image_properties(no_padding_text)[:width].to_i
      @height = image_properties(no_padding_text)[:height].to_i
    end
    it "1 number shortcut" do
      image, meta = @generator.call(@text, :padding => '10')
      image.should have_width(@width + 20)
      image.should have_height(@height + 20)
    end
    it "2 numbers shortcut" do
      image, meta = @generator.call(@text, :padding => '10 5')
      image.should have_width(@width + 10)
      image.should have_height(@height + 20)
    end
    it "3 numbers shortcut" do
      image, meta = @generator.call(@text, :padding => '10 5 8')
      image.should have_width(@width + 10)
      image.should have_height(@height + 18)
    end
    it "4 numbers shortcut" do
      image, meta = @generator.call(@text, :padding => '1 2 3 4')
      image.should have_width(@width + 6)
      image.should have_height(@height + 4)
    end
    it "should override the general padding declaration with the specific one (e.g. 'padding-left')" do
      image, meta = @generator.call(@text, :padding => '10', 'padding-left' => 9)
      image.should have_width(@width + 19)
      image.should have_height(@height + 20)
    end
    it "should ignore 'px' suffixes" do
      image, meta = @generator.call(@text, :padding => '1px 2px 3px 4px')
      image.should have_width(@width + 6)
      image.should have_height(@height + 4)
    end
    it "bad padding string" do
      lambda{
        @generator.call(@text, :padding => '1 2 3 4 5')
      }.should raise_error(ArgumentError)
    end
  end
end