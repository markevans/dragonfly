require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::Image do
  
  before(:each) do
    @gif_string = "GIF89a\001\000\001\000\360\000\000\377\377\377\000\000\000!\371\004\000\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
  end
  
  it "should raise an error if initialized with a non-string/file/tempfile" do
    lambda{
      Imagetastic::Image.new(3)
    }.should raise_error(ArgumentError)
  end
  
  describe "initializing from a string" do
    before(:each) do
      @image = Imagetastic::Image.new(@gif_string)
    end
    describe "data" do
      it "should return the data correctly" do
        @image.data.should == @gif_string
      end
    end
    describe "file" do
      it "should lazily create a closed tempfile" do
        @image.file.should be_a(Tempfile)
        @image.file.should be_closed
      end
      it "should contain the correct data" do
        @image.file.open.read.should == @gif_string
      end
    end
  end
  
  describe "initializing from a tempfile" do
    before(:each) do
      @tempfile = Tempfile.new('test')
      @tempfile.write(@gif_string)
      @tempfile.close
      @image = Imagetastic::Image.new(@tempfile)
    end
    describe "data" do
      it "should lazily return the correct data" do
        @image.data.should == @gif_string
      end
    end
    describe "file" do
      it "should return the closed tempfile" do
        @image.file.should be_a(Tempfile)
        @image.file.should be_closed
        @image.file.path.should == @tempfile.path
      end
    end
  end
  
  describe "initializing from a file" do
    before(:each) do
      @file = File.new(File.dirname(__FILE__)+'/../../samples/beach.png','r')
      @image = Imagetastic::Image.new(@file)
    end
    after(:each) do
      @file.close
    end
    describe "data" do
      it "should lazily return the correct data" do
        @image.data.should == @file.read
      end
    end
    describe "file" do
      it "should lazily return a closed tempfile" do
        @image.file.should be_a(Tempfile)
        @image.file.should be_closed
      end
      it "should contain the correct data" do
        @image.file.open.read.should == @file.read
      end
    end
  end
  
  describe "each" do
    before(:each) do
      @file = File.new(File.dirname(__FILE__)+'/../../samples/beach.png','r')
      @image = Imagetastic::Image.new(@file)
    end
    it "should yield a number of bytes each time" do
      parts = []
      @image.each do |bytes|
        parts << bytes
      end
      parts.length.should >= 2 # Sanity check to check that the sample file is adequate for this test
      parts[0...-1].each do |part|
        part.length.should == 8192
      end
      parts.last.length.should <= 8192
    end
  end
  
end