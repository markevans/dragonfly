require 'spec_helper'

describe Dragonfly::ImageMagick::Generators::Plain do
  before(:each) do
    @generator = Dragonfly::ImageMagick::Generators::Plain.new
  end

  describe "of given dimensions and colour" do
    before(:each) do
      @image, @meta = @generator.call(23,12,'white')
    end
    it {@image.should have_width(23)}
    it {@image.should have_height(12)}
    it {@image.should have_format('png')}
    it {@meta.should == {:format => :png, :name => 'plain.png'}}
  end

  it "should cope with colour name format" do
    image, meta = @generator.call(1, 1, 'red')
    image.should have_width(1)
  end

  it "should cope with rgb format" do
    image, meta = @generator.call(1, 1, 'rgb(244,255,1)')
    image.should have_width(1)
  end

  it "should cope with rgb percent format" do
    image, meta = @generator.call(1, 1, 'rgb(100%,50%,20%)')
    image.should have_width(1)
  end

  it "should cope with hex format" do
    image, meta = @generator.call(1, 1, '#fdafda')
    image.should have_width(1)
  end

  it "should cope with uppercase hex format" do
    image, meta = @generator.call(1, 1, '#FDAFDA')
    image.should have_width(1)
  end

  it "should cope with shortened hex format" do
    image, meta = @generator.call(1, 1, '#fda')
    image.should have_width(1)
  end

  it "should cope with 'transparent'" do
    image, meta = @generator.call(1, 1, 'transparent')
    image.should have_width(1)
  end

  it "should cope with rgba format" do
    image, meta = @generator.call(1, 1, 'rgba(25,100,255,0.5)')
    image.should have_width(1)
  end

  it "should cope with hsl format" do
    image, meta = @generator.call(1, 1, 'hsl(25,100,255)')
    image.should have_width(1)
  end

  it "should blow up with an invalid colour" do
    lambda{
      @generator.call(1,1,'rgb(doogie)')
    }.should_not raise_error()
  end

  describe "specifying the format" do
    before(:each) do
      @image, @meta = @generator.call(23, 12, 'white', :format => :gif)
    end
    it {@image.should have_format('gif')}
    it {@meta.should == {:format => :gif, :name => 'plain.gif'}}
  end

end
