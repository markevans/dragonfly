require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'

describe Dragonfly::DataStorage::FileDataStore do
  
  before(:each) do
    @data_store = Dragonfly::DataStorage::FileDataStore.new
    @data_store.root_path = '/var/tmp/dragonfly_test'
    
    # Set 'now' to a date in the past
    Time.stub!(:now).and_return Time.mktime(1984,"may",4,14,28,1)
    @file_pattern_prefix_without_root = '1984/05/04/142801'
    @file_pattern_prefix = "#{@data_store.root_path}/#{@file_pattern_prefix_without_root}"
  end
  
  after(:each) do
    # Clean up created files
    FileUtils.rm_rf("#{@data_store.root_path}/1984")
  end
  
  it_should_behave_like 'data_store'
  
  before(:each) do
    @temp_object = Dragonfly::TempObject.new('goobydoo')
  end
  
  describe "store" do
    
    def it_should_write_to_file(storage_path, temp_object)
      FileUtils.should_receive(:cp).with(temp_object.path, storage_path)
    end
    
    it "should store the file in a folder based on date, with default filename" do
      it_should_write_to_file("#{@file_pattern_prefix}_file", @temp_object)
      @data_store.store(@temp_object)
    end

    it "should use the temp_object name if it exists" do
      @temp_object.name = 'hello'
      it_should_write_to_file("#{@file_pattern_prefix}_hello", @temp_object)
      @data_store.store(@temp_object)
    end
    
    it "should strip the extension of the temp_object name" do
      @temp_object.name = 'hello.you.png'
      it_should_write_to_file("#{@file_pattern_prefix}_hello.you", @temp_object)
      @data_store.store(@temp_object)
    end

    it "should use the default file suffix if the temp_object name is blank" do
      @temp_object.name = ''
      it_should_write_to_file("#{@file_pattern_prefix}_file", @temp_object)
      @data_store.store(@temp_object)
    end

    describe "when the filename already exists" do

      it "should store the file with a numbered suffix" do
        FileUtils.mkdir_p(@file_pattern_prefix)
        FileUtils.touch("#{@file_pattern_prefix}_file")
        it_should_write_to_file("#{@file_pattern_prefix}_file_2", @temp_object)
        @data_store.store(@temp_object)
      end
    
      it "should store the file with a numbered suffix taking into account the name" do
        @temp_object.name = 'hello.png'
        FileUtils.mkdir_p(@file_pattern_prefix)
        FileUtils.touch("#{@file_pattern_prefix}_hello")
        it_should_write_to_file("#{@file_pattern_prefix}_hello_2", @temp_object)
        @data_store.store(@temp_object)
      end
    
      it "should store the file with an incremented number suffix" do
        FileUtils.mkdir_p(@file_pattern_prefix)
        FileUtils.touch("#{@file_pattern_prefix}_file")
        FileUtils.touch("#{@file_pattern_prefix}_file_2")
        it_should_write_to_file("#{@file_pattern_prefix}_file_3", @temp_object)
        @data_store.store(@temp_object)
      end

    end

    describe "return value" do

      it "should return the filepath without the root of the stored file when a file name is not provided" do
        @data_store.store(@temp_object).should == "#{@file_pattern_prefix_without_root}_file"
      end
    
      it "should return the filepath without the root of the stored file when a file name is provided" do
        @temp_object.name = 'hello.you.png'
        @data_store.store(@temp_object).should == "#{@file_pattern_prefix_without_root}_hello.you"
      end
    
    end

  end
  
  describe "errors" do

    it "should raise an error if it can't create a directory" do
      FileUtils.should_receive(:mkdir_p).and_raise(Errno::EACCES)
      lambda{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::UnableToStore)
    end
  
    it "should raise an error if it can't create a file" do
      FileUtils.should_receive(:cp).and_raise(Errno::EACCES)
      lambda{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::UnableToStore)
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