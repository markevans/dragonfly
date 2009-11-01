require File.dirname(__FILE__) + '/../../spec_helper'

describe "data_store", :shared => true do

  # Using these shared spec requires you to set the inst var @data_store
  
  before(:each) do
    @temp_object = Dragonfly::TempObject.new('gollum')
  end

  describe "store" do
    it "should return a unique identifier for each storage" do
      @data_store.store(@temp_object).should_not == @data_store.store(@temp_object)
    end
  end
  
  describe "retrieve" do
    it "should retrieve the stored data" do
      uid = @data_store.store(@temp_object)
      Dragonfly::TempObject.new(@data_store.retrieve(uid)).data.should == @temp_object.data
    end

    it "should raise an exception if the data doesn't exist" do
      lambda{
        @data_store.retrieve('gooble/gubbub')
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end
  
  describe "destroy" do
    
    it "should destroy the stored data" do
      uid = @data_store.store(@temp_object)
      @data_store.destroy(uid)
      lambda{
        @data_store.retrieve(uid)
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
    
    it "should raise an error if the data doesn't exist" do
      lambda{
        @data_store.destroy('gooble/gubbub')
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end

end