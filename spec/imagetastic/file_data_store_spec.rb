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
  end
  
  describe "retrieve" do
  end
  
end