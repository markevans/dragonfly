require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::TempObject do
  
  it "should raise an error if initialized with a non-string/file/tempfile" do
    lambda{
      Imagetastic::TempObject.new(3)
    }.should raise_error(ArgumentError)
  end
  
  describe "common behaviour for #each", :shared => true do
    it "should yield a number of bytes each time" do
      parts = []
      @temp_object.each do |bytes|
        parts << bytes
      end
      parts.length.should >= 2 # Sanity check to check that the sample file is adequate for this test
      parts[0...-1].each do |part|
        part.length.should == 8192
      end
      parts.last.length.should <= 8192
    end
  end
  
  describe "initializing from a string" do
    before(:each) do
      @gif_string = File.new(File.dirname(__FILE__)+'/../../samples/round.gif','r').read
      @temp_object = Imagetastic::TempObject.new(@gif_string)
    end
    describe "data" do
      it "should return the data correctly" do
        @temp_object.data.should == @gif_string
      end
    end
    describe "file" do
      it "should lazily create a closed tempfile" do
        @temp_object.file.should be_a(Tempfile)
        @temp_object.file.should be_closed
      end
      it "should contain the correct data" do
        @temp_object.file.open.read.should == @gif_string
      end
    end
    describe "each" do
      it "should not create a file" do
        @temp_object.should_not_receive(:tempfile)
        @temp_object.each{}
      end
      it_should_behave_like "common behaviour for #each"
    end
  end
  
  describe "initializing from a tempfile" do
    before(:each) do
      @gif_string = File.new(File.dirname(__FILE__)+'/../../samples/round.gif','r').read
      @tempfile = Tempfile.new('test')
      @tempfile.write(@gif_string)
      @tempfile.close
      @temp_object = Imagetastic::TempObject.new(@tempfile)
    end
    describe "data" do
      it "should lazily return the correct data" do
        @temp_object.data.should == @gif_string
      end
    end
    describe "file" do
      it "should return the closed tempfile" do
        @temp_object.file.should be_a(Tempfile)
        @temp_object.file.should be_closed
        @temp_object.file.path.should == @tempfile.path
      end
    end
    describe "each" do
      it "should not create a data string" do
        @temp_object.should_not_receive(:data)
        @temp_object.each{}
      end
      it_should_behave_like "common behaviour for #each"
    end
  end
  
  describe "initializing from a file" do
    before(:each) do
      @file = File.new(File.dirname(__FILE__)+'/../../samples/beach.png','r')
      @temp_object = Imagetastic::TempObject.new(@file)
    end
    after(:each) do
      @file.close
    end
    describe "data" do
      it "should lazily return the correct data" do
        @temp_object.data.should == @file.read
      end
    end
    describe "file" do
      it "should lazily return a closed tempfile" do
        @temp_object.file.should be_a(Tempfile)
        @temp_object.file.should be_closed
      end
      it "should contain the correct data" do
        @temp_object.file.open.read.should == @file.read
      end
    end
    describe "each" do
      it "should not create a data string" do
        @temp_object.should_not_receive(:data)
        @temp_object.each{}
      end
      it_should_behave_like "common behaviour for #each"
    end
  end
  
  describe "path" do
    it "should return the absolute file path" do
      temp_object = Imagetastic::TempObject.new(File.new(File.dirname(__FILE__)+'/../../samples/beach.png','r'))
      temp_object.path.should == temp_object.file.path
    end
  end
  
  describe ".from_file" do
    it "should be the same as initializing from a file object, but using just the path" do
      path = File.dirname(__FILE__)+'/../../samples/beach.png'
      image1 = Imagetastic::TempObject.from_file(path)
      image2 = Imagetastic::TempObject.new(File.new(path,'r'))
      image1.data.should == image2.data
    end
  end
  
end