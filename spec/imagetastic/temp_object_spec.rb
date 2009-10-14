require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::TempObject do
  
  def new_tempfile(data = File.read(SAMPLES_DIR + '/round.gif'))
    tempfile = Tempfile.new('test')
    tempfile.write(data)
    tempfile.close
    tempfile
  end
  
  def new_file(data = File.read(SAMPLES_DIR + '/round.gif'))
    File.open('/tmp/test_file', 'w') do |f|
      f.write(data)
    end
    File.new('/tmp/test_file')
  end
  
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
      @gif_string = File.read(SAMPLES_DIR + '/round.gif')
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
      @gif_string = File.read(SAMPLES_DIR + '/round.gif')
      @tempfile = new_tempfile(@gif_string)
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
      @file = File.new(SAMPLES_DIR + '/beach.png')
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
  
  describe "initializing from another temp object" do
    before(:each) do
      @temp_object1 = Imagetastic::TempObject.new(new_tempfile('hello'))
      @temp_object2 = Imagetastic::TempObject.new(@temp_object1)
    end
    it "should not be the same object" do
      @temp_object1.should_not == @temp_object2
    end
    it "should have the same data" do
      @temp_object1.data.should == @temp_object2.data
    end
    it "should have a different file path" do
      @temp_object1.path.should_not == @temp_object2.path
    end
  end
  
  describe "path" do
    it "should return the absolute file path" do
      temp_object = Imagetastic::TempObject.new(File.new(SAMPLES_DIR + '/beach.png'))
      temp_object.path.should == temp_object.file.path
    end
  end
  
  describe "modify_self!" do

    before(:each) do
      @temp_object = Imagetastic::TempObject.new('DATA_ONE')
      @temp_object.data # Make sure internal stuff is initialized
      @temp_object.file #
    end
    it "should modify itself" do
      @temp_object.modify_self!('DATA_TWO')
      @temp_object.data.should == 'DATA_TWO'
    end
    it "should return itself" do
      @temp_object.modify_self!('DATA_TWO').should == @temp_object
    end
    it "should modify itself when the new object is a file" do
      @temp_object.modify_self!(File.new(SAMPLES_DIR + '/beach.png'))
      @temp_object.data.should == File.read(SAMPLES_DIR + '/beach.png')
    end
    it "should modify itself when the new object is a tempfile" do
      tempfile = new_tempfile
      data = tempfile.open.read
      @temp_object.modify_self!(tempfile)
      @temp_object.data.should == data
    end
    
  end
  
  describe "size" do
    
    before(:each) do
      @gif_string = File.read(SAMPLES_DIR + '/round.gif')
    end
    
    it "should return the size in bytes when initialized with a string" do
      Imagetastic::TempObject.new(@gif_string).size.should == 61346
    end
    it "should return the size in bytes when initialized with a tempfile" do
      Imagetastic::TempObject.new(new_tempfile(@gif_string)).size.should == 61346
    end
    it "should return the size in bytes when initialized with a file" do
      Imagetastic::TempObject.new(new_file(@gif_string)).size.should == 61346
    end
  end
  
  describe "name" do
    before(:each) do
      @obj = new_tempfile
    end
    it "should set the name if the initial object responds to 'original filename'" do
      def @obj.original_filename
        'jimmy.page'
      end
      Imagetastic::TempObject.new(@obj).name.should == 'jimmy.page'
    end
    it "should not set the name if the initial object doesn't respond to 'original filename'" do
      Imagetastic::TempObject.new(@obj).name.should be_nil
    end
  end
  
end