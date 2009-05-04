require File.dirname(__FILE__) + '/../spec_helper'

describe Imagetastic::DataStorage::FileDataStore do
  
  before(:each) do
    @data_store = Imagetastic::DataStorage::FileDataStore.new
  end
  
  describe "store" do
    before(:each) do
      @file_pattern_prefix = "#{Imagetastic::DataStorage::FileDataStore::IMAGE_STORE_ROOT}/#{Date.today.year}/\\d{2}/\\d{2}/\\d\\d_\\d\\d_\\d\\d"
    end
    
    it "should store the file in a folder based on date, with default filename" do
      File.should_receive(:open).with(string_matching(/^#{@file_pattern_prefix}_image$/), 'w')
      @data_store.store('blah')
    end

    it "should store the file in a folder based on date and use the name passed in if given" do
      File.should_receive(:open).with(string_matching(/^#{@file_pattern_prefix}_toby$/), 'w')
      @data_store.store('blah', 'toby')
    end

    it "should return the filepath of the stored file" do
      @data_store.store('blah').should =~ /^#{@file_pattern_prefix}_image$/
    end
    
    it "should raise an error if it can't create a directory" do
      FileUtils.should_receive(:mkdir_p).and_raise(Errno::EACCES)
      lambda{
        @data_store.store('goo')
      }.should raise_error(Imagetastic::DataStorage::UnableToStore)
    end
    
  end
  
  describe "retrieve" do
    it "should retrieve the data stored, given the unique id (filepath)" do
      id = @data_store.store('this is data!')
      @data_store.retrieve(id).should == 'this is data!'
    end
    
    it "should raise an exception if the data doesn't exist" do
      lambda{
        @data_store.retrieve('/tmp/gubbub')
      }.should raise_error(Imagetastic::DataStorage::DataNotFound)
    end
  end
  
end