require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'

describe Imagetastic::DataStorage::FileDataStore do
  
  before(:each) do
    @data_store = Imagetastic::DataStorage::FileDataStore.new
    
    # Set 'now' to a date in the past
    Time.stub!(:now).and_return Time.mktime(1984,"may",4,14,28,1)
    @file_pattern_prefix_without_root = '1984/05/04/14_28_01'
    @file_pattern_prefix = "#{@data_store.root_path}/#{@file_pattern_prefix_without_root}"
  end
  
  after(:each) do
    # Clean up created files
    FileUtils.rm_rf("#{@data_store.root_path}/1984")
  end
  
  it_should_behave_like 'data_store'
  
  describe "store" do
    
    def it_should_write_to_file(file_path, data)
      file = mock('file')
      File.should_receive(:open).with(file_path, 'w').and_yield(file)
      file.should_receive(:write).with(data)
    end
    
    it "should store the file in a folder based on date, with default filename" do
      it_should_write_to_file("#{@file_pattern_prefix}_image", 'blah')
      @data_store.store('blah')
    end

    it "should store the file in a folder based on date and use the name passed in if given" do
      it_should_write_to_file("#{@file_pattern_prefix}_toby", 'blah')
      @data_store.store('blah', 'toby')
    end

    it "should store the file with a numbered suffix if the filename already exists" do
      File.should_receive(:exist?).with("#{@file_pattern_prefix}_image").and_return(true)
      File.should_receive(:exist?).with("#{@file_pattern_prefix}_image_2").and_return(false)
      it_should_write_to_file("#{@file_pattern_prefix}_image_2", 'goobydoo')
      @data_store.store('goobydoo')
    end
    
    it "should store the file with an incremented number suffix if the filename already exists" do
      File.should_receive(:exist?).with("#{@file_pattern_prefix}_image").and_return(true)
      File.should_receive(:exist?).with("#{@file_pattern_prefix}_image_2").and_return(true)
      File.should_receive(:exist?).with("#{@file_pattern_prefix}_image_3").and_return(false)
      it_should_write_to_file("#{@file_pattern_prefix}_image_3", 'goobydoo')
      @data_store.store('goobydoo')
    end

    it "should return the filepath without the root of the stored file" do
      @data_store.store('blah').should == "#{@file_pattern_prefix_without_root}_image"
    end
    
    it "should raise an error if it can't create a directory" do
      FileUtils.should_receive(:mkdir_p).and_raise(Errno::EACCES)
      lambda{ @data_store.store('goo') }.should raise_error(Imagetastic::DataStorage::UnableToStore)
    end
    
    it "should raise an error if it can't create a file" do
      file = mock('file')
      File.should_receive(:open).and_yield(file)
      file.should_receive(:write).and_raise(Errno::EACCES)
      lambda{ @data_store.store('goo') }.should raise_error(Imagetastic::DataStorage::UnableToStore)
    end
    
  end
  
end