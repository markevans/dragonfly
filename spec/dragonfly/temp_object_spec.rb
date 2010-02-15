require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::TempObject do
  
  ####### Helper Methods #######

  def new_tempfile(data = File.read(SAMPLES_DIR + '/round.gif'))
    tempfile = Tempfile.new('test')
    tempfile.write(data)
    tempfile.rewind
    tempfile
  end
  
  def new_file(data = File.read(SAMPLES_DIR + '/round.gif'))
    File.open('/tmp/test_file', 'w') do |f|
      f.write(data)
    end
    File.new('/tmp/test_file')
  end
  
  def get_parts(temp_object)
    parts = []
    temp_object.each do |bytes|
      parts << bytes
    end
    parts.length.should >= 2 # Sanity check to check that the sample file is adequate for this test
    parts
  end
  
  ###############################
  
  it "should raise an error if initialized with a non-string/file/tempfile" do
    lambda{
      Dragonfly::TempObject.new(3)
    }.should raise_error(ArgumentError)
  end
  
  describe "common behaviour for #each", :shared => true do

    it "should yield 8192 bytes each time" do
      parts = get_parts(@temp_object)
      parts[0...-1].each do |part|
        part.bytesize.should == 8192
      end
      parts.last.bytesize.should <= 8192
    end
    
  end
  
  describe "configuring #each" do

    it "should yield the number of bytes specified in the class configuration" do
      temp_object_class = Class.new(Dragonfly::TempObject)
      temp_object_class.block_size = 3001
      temp_object = temp_object_class.new(new_tempfile)
      parts = get_parts(temp_object)
      parts[0...-1].each do |part|
        part.length.should == 3001
      end
      parts.last.length.should <= 3001
    end

  end
  
  describe "initializing from a string" do
    before(:each) do
      @gif_string = File.read(SAMPLES_DIR + '/round.gif')
      @temp_object = Dragonfly::TempObject.new(@gif_string)
    end
    describe "data" do
      it "should return the data correctly" do
        @temp_object.data.should == @gif_string
      end
    end
    describe "file" do
      it "should lazily create an unclosed tempfile" do
        @temp_object.file.should be_a(Tempfile)
        @temp_object.file.should_not be_closed
      end
      it "should contain the correct data" do
        @temp_object.file.read.should == @gif_string
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
      @temp_object = Dragonfly::TempObject.new(@tempfile)
    end
    describe "data" do
      it "should lazily return the correct data" do
        @temp_object.data.should == @gif_string
      end
    end
    describe "file" do
      it "should return the unclosed tempfile" do
        @temp_object.file.should be_a(Tempfile)
        @temp_object.file.should_not be_closed
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
      @temp_object = Dragonfly::TempObject.new(@file)
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
      it "should lazily return an unclosed tempfile" do
        @temp_object.file.should be_a(Tempfile)
        @temp_object.file.should_not be_closed
      end
      it "should contain the correct data" do
        @temp_object.file.read.should == @file.read
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
      @temp_object1 = Dragonfly::TempObject.new(new_tempfile('hello'))
      @temp_object2 = Dragonfly::TempObject.new(@temp_object1)
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
      temp_object = Dragonfly::TempObject.new(File.new(SAMPLES_DIR + '/beach.png'))
      temp_object.path.should == temp_object.file.path
    end
  end
  
  describe "modify_self!" do

    before(:each) do
      @temp_object = Dragonfly::TempObject.new('DATA_ONE')
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
      data = tempfile.read
      @temp_object.modify_self!(tempfile)
      @temp_object.data.should == data
    end
    it "should still work when the object is itself" do
      @temp_object.modify_self!(@temp_object)
      @temp_object.data.should == 'DATA_ONE'
    end
    
  end
  
  describe "size" do
    
    before(:each) do
      @gif_string = File.read(SAMPLES_DIR + '/round.gif')
    end
    
    it "should return the size in bytes when initialized with a string" do
      Dragonfly::TempObject.new(@gif_string).size.should == 61346
    end
    it "should return the size in bytes when initialized with a tempfile" do
      Dragonfly::TempObject.new(new_tempfile(@gif_string)).size.should == 61346
    end
    it "should return the size in bytes when initialized with a file" do
      Dragonfly::TempObject.new(new_file(@gif_string)).size.should == 61346
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
      Dragonfly::TempObject.new(@obj).name.should == 'jimmy.page'
    end
    it "should not set the name if the initial object doesn't respond to 'original filename'" do
      Dragonfly::TempObject.new(@obj).name.should be_nil
    end
    it "should set the name if the initial object is a file object" do
      file = File.new(SAMPLES_DIR + '/round.gif')
      temp_object = Dragonfly::TempObject.new(file)
      temp_object.name.should == 'round.gif'
    end
    it "should still be nil if set to empty string" do
      temp_object = Dragonfly::TempObject.new('sdf')
      temp_object.name = ''
      temp_object.name.should be_nil
    end
  end
  
  describe "ext" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('asfsadf')
    end
    it "should use the correct extension from name" do
      @temp_object.name = 'hello.there.mate'
      @temp_object.ext.should == 'mate'
    end
    it "should be nil if name has none" do
      @temp_object.name = 'hello'
      @temp_object.ext.should be_nil
    end
    it "should be nil if name is nil" do
      @temp_object.name = nil
      @temp_object.ext.should be_nil
    end
  end
  
  describe "basename" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('asfsadf')
    end
    it "should use the correct basename from name" do
      @temp_object.name = 'hello.there.mate'
      @temp_object.basename.should == 'hello.there'
    end
    it "should be the name if it has no ext" do
      @temp_object.name = 'hello'
      @temp_object.basename.should == 'hello'
    end
    it "should be nil if name is nil" do
      @temp_object.name = nil
      @temp_object.basename.should be_nil
    end
  end
  
  describe "to_file" do
    
    describe "common behaviour for to_file", :shared => true do
      before(:each) do
        @filename = 'eggnog.txt'
        FileUtils.rm(@filename) if File.exists?(@filename)
      end
      after(:each) do
        FileUtils.rm(@filename) if File.exists?(@filename)
      end
      it "should write to a file" do
        @temp_object.to_file(@filename)
        File.exists?(@filename).should be_true
      end
      it "should write the correct data to the file" do
        @temp_object.to_file(@filename)
        File.read(@filename).should == 'HELLO'
      end
      it "should return a readable file" do
        file = @temp_object.to_file(@filename)
        file.should be_a(File)
        file.read.should == 'HELLO'
      end
    end
    
    describe "when initialized with a string" do
      before(:each){ @temp_object = Dragonfly::TempObject.new('HELLO') }
      it_should_behave_like "common behaviour for to_file"
    end
    
    describe "when initialized with a file" do
      before(:each){ @temp_object = Dragonfly::TempObject.new(new_tempfile('HELLO')) }
      it_should_behave_like "common behaviour for to_file"
    end
    
    describe "when initialized with a tempfile" do
      before(:each){ @temp_object = Dragonfly::TempObject.new(new_file('HELLO')) }
      it_should_behave_like "common behaviour for to_file"
    end

  end
  
end