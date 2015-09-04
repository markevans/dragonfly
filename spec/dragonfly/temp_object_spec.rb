require 'spec_helper'

describe Dragonfly::TempObject do

  ####### Helper Methods #######

  def sample_path(filename)
    SAMPLES_DIR.join(filename)
  end

  def new_tempfile(data='HELLO')
    tempfile = Tempfile.new('test')
    tempfile.write(data)
    tempfile.rewind
    tempfile
  end

  def new_file(data='HELLO', path="tmp/test_file")
    File.open(path, 'w') do |f|
      f.write(data)
    end
    File.new(path)
  end

  def new_pathname(data='HELLO', path="tmp/test_file")
    File.open(path, 'w') do |f|
      f.write(data)
    end
    Pathname.new(path)
  end

  def new_temp_object(data, klass=Dragonfly::TempObject)
    klass.new(initialization_object(data))
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

  shared_examples_for "common behaviour" do

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
        it "should enable reading the file twice" do
          @temp_object.file{|f| f.read }.should == "HELLO"
          @temp_object.file{|f| f.read }.should == "HELLO"
        end
      end

      describe "path" do
        it "should return an absolute file path" do
          if Dragonfly.running_on_windows?
            @temp_object.path.should =~ %r{^[a-zA-Z]:/\w+}
          else
            @temp_object.path.should =~ %r{^/\w+}
          end
        end
      end

      describe "size" do
        it "should return the size in bytes" do
          @temp_object.size.should == 5
        end
      end

      describe "to_file" do
        before(:each) do
          @filename = 'tmp/eggnog.txt'
          FileUtils.rm_f(@filename) if File.exists?(@filename)
        end
        after(:each) do
          FileUtils.rm_f(@filename) if File.exists?(@filename)
        end
        it "should write to a file" do
          @temp_object.to_file(@filename)
          File.exists?(@filename).should be_truthy
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
        it "should have 644 permissions" do
          @temp_object.to_file(@filename)
          File::Stat.new(@filename).mode.to_s(8).should =~ /644$/
        end
        it "should allow setting different permissions" do
          @temp_object.to_file(@filename, :mode => 0755)
          File::Stat.new(@filename).mode.to_s(8).should =~ /755$/
        end
        it "should create intermediate subdirs" do
          filename = 'tmp/gog/mcgee'
          @temp_object.to_file(filename)
          File.exists?(filename).should be_truthy
          FileUtils.rm_rf('tmp/gog')
        end
        it "should allow not creating intermediate subdirs" do
          filename = 'tmp/gog/mcgee'
          expect{ @temp_object.to_file(filename, :mkdirs => false) }.to raise_error()
        end
      end

      describe "to_tempfile" do
        it "returns a new open tempfile" do
          tempfile = @temp_object.to_tempfile
          tempfile.should be_a(Tempfile)
          tempfile.path.should_not == @temp_object.path
          tempfile.read.should == @temp_object.data
          tempfile.should_not be_closed
        end
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
    end

    describe "closing" do
      before(:each) do
        @temp_object = new_temp_object("wassup")
      end
      %w(file data).each do |method|
        it "should raise error when calling #{method}" do
          @temp_object.close
          expect{
            @temp_object.send(method)
          }.to raise_error(Dragonfly::TempObject::Closed)
        end
      end
      it "should not report itself as closed to begin with" do
        @temp_object.should_not be_closed
      end
      it "should report itself as closed after closing" do
        @temp_object.close
        @temp_object.should be_closed
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

    it "should delete its internal tempfile on close" do
      temp_object = new_temp_object("HELLO")
      path = temp_object.path
      File.exist?(path).should be_truthy
      temp_object.close
      File.exist?(path).should be_falsey
    end

 end

  describe "initializing from a tempfile" do

    def initialization_object(data)
      @tempfile = new_tempfile(data)
    end

    it_should_behave_like "common behaviour"

    it "should not create a data string when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:data)
      temp_object.each{}
    end

    it "should return the tempfile's path" do
      temp_object = new_temp_object('HELLO')
      temp_object.path.should == @tempfile.path
    end

    it "should delete its internal tempfile on close" do
      temp_object = new_temp_object("HELLO")
      path = temp_object.path
      File.exist?(path).should be_truthy
      temp_object.close
      File.exist?(path).should be_falsey
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

    it "should return the file's path" do
      file = new_file('HELLO')
      temp_object = Dragonfly::TempObject.new(file)
      temp_object.path.should == File.expand_path(file.path)
    end

    it "should return an absolute path even if the file wasn't instantiated like that" do
      file = new_file('HELLO', 'tmp/bongo')
      temp_object = Dragonfly::TempObject.new(file)
      if Dragonfly.running_on_windows?
        temp_object.path.should =~ %r{^[a-zA-Z]:/\w.*bongo}
      else
        temp_object.path.should =~ %r{^/\w.*bongo}
      end
      file.close
      FileUtils.rm(file.path)
    end

    it "doesn't remove the file on close" do
      temp_object = new_temp_object("HELLO")
      temp_object.close
      File.exist?(temp_object.path).should be_truthy
    end
  end

  describe "initializing from a pathname" do

    def initialization_object(data)
      new_pathname(data)
    end

    it_should_behave_like "common behaviour"

    it "should not create a data string when calling each" do
      temp_object = new_temp_object('HELLO')
      temp_object.should_not_receive(:data)
      temp_object.each{}
    end

    it "should return the file's path" do
      pathname = new_pathname('HELLO')
      temp_object = Dragonfly::TempObject.new(pathname)
      temp_object.path.should == File.expand_path(pathname.to_s)
    end

    it "should return an absolute path even if the pathname is relative" do
      pathname = new_pathname('HELLO', 'tmp/bingo')
      temp_object = Dragonfly::TempObject.new(pathname)
      if Dragonfly.running_on_windows?
        temp_object.path.should =~ %r{^[a-zA-Z]:/\w.*bingo}
      else
        temp_object.path.should =~ %r{^/\w.*bingo}
      end
      pathname.delete
    end

    it "doesn't remove the file on close" do
      temp_object = new_temp_object("HELLO")
      temp_object.close
      File.exist?(temp_object.path).should be_truthy
    end

  end

  describe "initializing from another temp object" do

    def initialization_object(data)
      Dragonfly::TempObject.new(data)
    end

    before(:each) do
      @temp_object1 = Dragonfly::TempObject.new(new_tempfile('hello'))
      @temp_object2 = Dragonfly::TempObject.new(@temp_object1)
    end

    it_should_behave_like "common behaviour"

    it "should not be the same object" do
      @temp_object1.should_not == @temp_object2
    end
    it "should have the same data" do
      @temp_object1.data.should == @temp_object2.data
    end
    it "should have the same file path" do
      @temp_object1.path.should == @temp_object2.path
    end
  end

  describe "initialize from a Rack::Test::UploadedFile" do
    def initialization_object(data)
      # The criteria we're using to determine if an object is a
      # Rack::Test::UploadedFile is if it responds to path
      #
      # We can't just check if it is_a?(Rack::Test::UploadedFile) because that
      # class may not always be present.
      uploaded_file = double("mock_uploadedfile")
      uploaded_file.stub(:path).and_return File.expand_path('tmp/test_file')
      uploaded_file.stub(:original_filename).and_return('foo.jpg')

      # Create a real file with the contents required at the correct path
      new_file(data, 'tmp/test_file')

      uploaded_file
    end

    it_should_behave_like "common behaviour"
  end

  describe "name" do

    before(:each) do
      @obj = new_tempfile
    end

    it "should set the name from the arg passed in" do
      Dragonfly::TempObject.new(@obj, 'goof.ball').name.should == 'goof.ball'
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
      file = File.new(SAMPLES_DIR.join('round.gif'))
      temp_object = Dragonfly::TempObject.new(file)
      temp_object.name.should == 'round.gif'
    end

    it "should set the name if the initial object is a pathname" do
      pathname = Pathname.new(SAMPLES_DIR + '/round.gif')
      temp_object = Dragonfly::TempObject.new(pathname)
      temp_object.name.should == 'round.gif'
    end

  end

  describe "ext" do

    let(:temp_object) { Dragonfly::TempObject.new("stuff") }

    it "defaults to nil" do
      temp_object.ext.should be_nil
    end

    it "uses name if present" do
      temp_object.should_receive(:name).and_return('some.thing.yo')
      temp_object.ext.should == 'yo'
    end

  end

end
