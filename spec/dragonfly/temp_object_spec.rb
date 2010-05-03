require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::TempObject do
  
  ####### Helper Methods #######

  def sample_path(filename)
    File.dirname(__FILE__) + '/../../samples/' + filename
  end

  def new_tempfile(data='HELLO')
    tempfile = Tempfile.new('test')
    tempfile.write(data)
    tempfile.rewind
    tempfile
  end
  
  def new_file(data='HELLO')
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
  
  describe "common behaviour", :shared => true do

    before(:each) do
      @temp_object = new_temp_object('HELLO')
    end

    describe "data" do
      it "should return the data correctly" do
        @temp_object.data.should == 'HELLO'
      end
    end

    describe "file" do
      it "should return a readable file" do
        @temp_object.file.should be_a(File)
      end
      it "should contain the correct data" do
        @temp_object.file.read.should == 'HELLO'
      end
      it "should yield a file then close it if a block is given" do
        @temp_object.file do |f|
          f.read.should == 'HELLO'
          f.should_receive :close
        end
      end
      it "should return whatever is returned from the block if a block is given" do
        @temp_object.file do |f|
          'doogie'
        end.should == 'doogie'
      end
    end

    describe "tempfile" do
      it "should create a closed tempfile" do
        @temp_object.tempfile.should be_a(Tempfile)
        @temp_object.tempfile.should be_closed
      end
      it "should contain the correct data" do
        @temp_object.tempfile.open.read.should == 'HELLO'
      end
    end
    
    describe "path" do
      it "should return the absolute file path" do
        @temp_object.path.should == @temp_object.tempfile.path
      end
    end
    
    describe "size" do
      it "should return the size in bytes" do
        @temp_object.size.should == 5
      end
    end

    describe "to_file" do
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

    describe "each" do
      it "should yield 8192 bytes each time" do
        temp_object = new_temp_object(File.read(sample_path('round.gif')))
        parts = get_parts(temp_object)
        parts[0...-1].each do |part|
          part.bytesize.should == 8192
        end
        parts.last.bytesize.should <= 8192
      end
      it "should yield the number of bytes specified in the class configuration" do
        klass = Class.new(Dragonfly::TempObject)
        temp_object = new_temp_object(File.read(sample_path('round.gif')), klass)
        klass.block_size = 3001
        parts = get_parts(temp_object)
        parts[0...-1].each do |part|
          part.length.should == 3001
        end
        parts.last.length.should <= 3001
      end
    end
    

  end
  
  describe "initializing from a string" do

    def new_temp_object(data, klass=Dragonfly::TempObject)
      klass.new(data)
    end

    it_should_behave_like "common behaviour"

    it "should not create a file when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:tempfile)
      temp_object.each{}
    end
  end
  
  describe "initializing from a tempfile" do

    def new_temp_object(data, klass=Dragonfly::TempObject)
      klass.new(new_tempfile(data))
    end

    it_should_behave_like "common behaviour"

    it "should not create a data string when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:data)
      temp_object.each{}
    end
  end
  
  describe "initializing from a file" do

    def new_temp_object(data, klass=Dragonfly::TempObject)
      klass.new(new_file(data))
    end

    it_should_behave_like "common behaviour"

    it "should not create a data string when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:data)
      temp_object.each{}
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
    it "should keep the same name" do
      @temp_object.name = 'billy.bob'
      @temp_object.modify_self!('WASSUP PUNk')
      @temp_object.name.should == 'billy.bob'
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

end
