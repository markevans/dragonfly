require File.dirname(__FILE__) + '/../../spec_helper'

describe "data_store", :shared => true do

  # Using these shared spec requires you to set the inst var @data_store

  describe "store" do
    it "should return a unique identifier for each storage" do
      temp_object = Imagetastic::TempObject.new('eggbert')
      @data_store.store(temp_object).should_not == @data_store.store(temp_object)
    end
  end
  
  describe "retrieve" do
    it "should retrieve the stored data" do
      temp_object = Imagetastic::TempObject.new('gollum')
      id = @data_store.store(temp_object)
      @data_store.retrieve(id).data.should == temp_object.data
    end

    it "should raise an exception if the data doesn't exist" do
      lambda{
        @data_store.retrieve('gooble/gubbub')
      }.should raise_error(Imagetastic::DataStorage::DataNotFound)
    end
  end

end