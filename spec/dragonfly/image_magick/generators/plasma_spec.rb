require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Plasma do
  before(:each) do
    @generator = Dragonfly::ImageMagick::Generators::Plasma.new
  end

  describe "of given dimensions" do
    before(:each) do
      @image, @meta = @generator.call(23,12)
    end
    it {@image.should have_width(23)}
    it {@image.should have_height(12)}
    it {@image.should have_format('png')}
    it {@meta.should == {:format => :png, :name => 'plasma.png'}}
  end

  describe "specifying the format" do
    before(:each) do
      @image, @meta = @generator.call(23, 12, :gif)
    end
    it {@image.should have_format('gif')}
    it {@meta.should == {:format => :gif, :name => 'plasma.gif'}}
  end
end
