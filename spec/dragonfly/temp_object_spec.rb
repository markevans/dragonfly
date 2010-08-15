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
  
  def new_temp_object(data, opts={})
    klass = opts.delete(:class) || Dragonfly::TempObject
    klass.new(initialization_object(data), opts)
  end
  
  def initialization_object(data)
    raise NotImplementedError, "This should be implemented in the describe block!"
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

    describe "simple initialization" do

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
      
    end

    describe "initializing attributes too" do
      it "should set the name" do
        temp_object = Dragonfly::TempObject.new(initialization_object('HELLO'), :name => 'monkey.egg')
        temp_object.name.should == 'monkey.egg'
      end
      it "should set the meta" do
        temp_object = Dragonfly::TempObject.new(initialization_object('HELLO'), :meta => {:dr => 'doolittle'})
        temp_object.meta.should == {:dr => 'doolittle'}
      end
      it "should set the format" do
        temp_object = Dragonfly::TempObject.new(initialization_object('HELLO'), :format => :jpg)
        temp_object.format.should == :jpg
      end
      it "should raise an error if an invalid option is given" do
        lambda {
          Dragonfly::TempObject.new(initialization_object('HELLO'), :doobie => 'doo')
        }.should raise_error(ArgumentError)
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
        temp_object = new_temp_object(File.read(sample_path('round.gif')), :class => klass)
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

    def initialization_object(data)
      data
    end

    it_should_behave_like "common behaviour"

    it "should not create a file when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:tempfile)
      temp_object.each{}
    end
  end
  
  describe "initializing from a tempfile" do

    def initialization_object(data)
      new_tempfile(data)
    end

    it_should_behave_like "common behaviour"

    it "should not create a data string when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:data)
      temp_object.each{}
    end
  end
  
  describe "initializing from a file" do

    def initialization_object(data)
      new_file(data)
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
    it "should still be nil if set to empty string on initialize" do
      temp_object = Dragonfly::TempObject.new('sdf', :name => '')
      temp_object.name.should be_nil
    end
  end
  
  describe "ext" do
    it "should use the correct extension from name" do
      temp_object = Dragonfly::TempObject.new('asfsadf', :name => 'hello.there.mate')
      temp_object.ext.should == 'mate'
    end
    it "should be nil if name has none" do
      temp_object = Dragonfly::TempObject.new('asfsadf', :name => 'hello')
      temp_object.ext.should be_nil
    end
    it "should be nil if name is nil" do
      temp_object = Dragonfly::TempObject.new('asfsadf')
      temp_object.ext.should be_nil
    end
  end

  describe "basename" do
    it "should use the correct basename from name" do
      temp_object = Dragonfly::TempObject.new('A', :name => 'hello.there.mate')
      temp_object.basename.should == 'hello.there'
    end
    it "should be the name if it has no ext" do
      temp_object = Dragonfly::TempObject.new('A', :name => 'hello')
      temp_object.basename.should == 'hello'
    end
    it "should be nil if name is nil" do
      temp_object = Dragonfly::TempObject.new('A', :name => nil)
      temp_object.basename.should be_nil
    end
  end
  
  describe "meta" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('get outta here!')
    end
    it "should return an empty hash if not set" do
      @temp_object.meta.should == {}
    end
    it "should allow setting" do
      @temp_object.meta[:teeth] = 'many'
      @temp_object.meta.should == {:teeth => 'many'}
    end
  end
  
  describe "format" do
    it "should return nil if not set" do
      temp_object = Dragonfly::TempObject.new('wassin my belly??!')
      temp_object.format.should be_nil
    end
    it "should allow setting on initialize" do
      temp_object = Dragonfly::TempObject.new('wassin my belly??!', :format => :jpg)
      temp_object.format.should == :jpg
    end
  end
  
  describe "extract_attributes_from" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new("ne'er gonna give you up",
        :meta => {:a => 4},
        :name => 'fred.txt'
      )
      @attributes = {:meta => {:b => 5}, :ogle => 'bogle'}
      @temp_object.extract_attributes_from(@attributes)
    end
    it "should overwrite its own attributes if specified" do
      @temp_object.meta.should == {:b => 5}
    end
    it "should leave non-specified attributes untouched" do
      @temp_object.name.should == 'fred.txt'
    end
    it "should remove attributes from the hash" do
      @attributes.should == {:ogle => 'bogle'}
    end
  end

end
