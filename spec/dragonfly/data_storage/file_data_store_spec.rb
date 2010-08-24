require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'

describe Dragonfly::DataStorage::FileDataStore do
  
  def touch_file(filename)
    FileUtils.mkdir_p(File.dirname(filename))
    FileUtils.touch(filename)
  end
  
  before(:each) do
    @data_store = Dragonfly::DataStorage::FileDataStore.new
    @data_store.root_path = '/var/tmp/dragonfly_test'
  end
  
  after(:each) do
    # Clean up created files
    FileUtils.rm_rf("#{@data_store.root_path}")
  end
  
  it_should_behave_like 'data_store'
  
  before(:each) do
    @temp_object = Dragonfly::TempObject.new('goobydoo')
  end
  
  describe "store" do
    
    def it_should_write_to_file(storage_path, temp_object)
      temp_object.should_receive(:to_file).with(storage_path).and_return(mock('file', :close => nil))
    end
    
    before(:each) do
      # Set 'now' to a date in the past
      Time.stub!(:now).and_return Time.mktime(1984,"may",4,14,28,1)
      @file_pattern_prefix_without_root = '1984/05/04/'
      @file_pattern_prefix = "#{@data_store.root_path}/#{@file_pattern_prefix_without_root}"
    end
    
    it "should store the file in a folder based on date, with default filename" do
      it_should_write_to_file("#{@file_pattern_prefix}file", @temp_object)
      @data_store.store(@temp_object)
    end

    it "should use the temp_object name if it exists" do
      @temp_object.should_receive(:name).at_least(:once).and_return('hello.there')
      it_should_write_to_file("#{@file_pattern_prefix}hello.there", @temp_object)
      @data_store.store(@temp_object)
    end

    it "should get rid of funny characters in the temp_object name" do
      @temp_object.should_receive(:name).at_least(:once).and_return('A Picture with many spaces in its name (at 20:00 pm).png')
      it_should_write_to_file("#{@file_pattern_prefix}A_Picture_with_many_spaces_in_its_name_at_20_00_pm_.png", @temp_object)
      @data_store.store(@temp_object)
    end

    describe "when the filename already exists" do

      it "should use a different filename" do
        touch_file("#{@file_pattern_prefix}file")
        @data_store.should_receive(:disambiguate).with('file').and_return('file_2')
        it_should_write_to_file("#{@file_pattern_prefix}file_2", @temp_object)
        @data_store.store(@temp_object)
      end
    
      it "should use a different filename taking into account the name and ext" do
        @temp_object.should_receive(:name).at_least(:once).and_return('hello.png')
        touch_file("#{@file_pattern_prefix}hello.png")
        @data_store.should_receive(:disambiguate).with('hello.png').and_return('blah.png')
        @data_store.store(@temp_object)
      end

      it "should keep trying until it finds a free filename" do
        touch_file("#{@file_pattern_prefix}file")
        touch_file("#{@file_pattern_prefix}file_2")
        @data_store.should_receive(:disambiguate).with('file').and_return('file_2')
        @data_store.should_receive(:disambiguate).with('file_2').and_return('file_3')
        it_should_write_to_file("#{@file_pattern_prefix}file_3", @temp_object)
        @data_store.store(@temp_object)
      end

    end

    describe "return value" do

      it "should return the filepath without the root of the stored file when a file name is not provided" do
        @data_store.store(@temp_object).should == "#{@file_pattern_prefix_without_root}file"
      end
    
      it "should return the filepath without the root of the stored file when a file name is provided" do
        @temp_object.should_receive(:name).at_least(:once).and_return('hello.you.png')
        @data_store.store(@temp_object).should == "#{@file_pattern_prefix_without_root}hello.you.png"
      end
    
    end

  end
  
  describe "disambiguate" do
    it "should add a suffix" do
      @data_store.disambiguate('file').should =~ /^file_\w+$/
    end
    it "should add a suffix to the basename" do
      @data_store.disambiguate('file.png').should =~ /^file_\w+\.png$/
    end
    it "should be random(-ish)" do
      @data_store.disambiguate('file').should_not == @data_store.disambiguate('file')
    end
  end
  
  describe "errors" do

    it "should raise an error if it can't create a directory" do
      FileUtils.should_receive(:mkdir_p).and_raise(Errno::EACCES)
      lambda{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::UnableToStore)
    end
  
    it "should raise an error if it can't create a file" do
      @temp_object.should_receive(:to_file).and_raise(Errno::EACCES)
      lambda{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::UnableToStore)
    end

  end
  
  describe "retrieve" do
    it "should be able to retrieve any file, stored or not (and without extra data)" do
      FileUtils.mkdir_p("#{@data_store.root_path}/jelly_beans/are")
      File.open("#{@data_store.root_path}/jelly_beans/are/good", 'w'){|f| f.write('hey dog') }
      file, meta = @data_store.retrieve("jelly_beans/are/good")
      file.read.should == 'hey dog'
      meta.should == {}
    end
  end
  
  describe "destroying" do

    it "should raise an error if the data doesn't exist" do
      lambda{
        @data_store.destroy('gooble/gubbub')
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end

    it "should prune empty directories when destroying" do
      uid = @data_store.store(@temp_object)
      @data_store.destroy(uid)
      @data_store.root_path.should be_an_empty_directory
    end

  end

end