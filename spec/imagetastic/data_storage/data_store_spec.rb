require File.dirname(__FILE__) + '/../../spec_helper'

describe "data_store", :shared => true do

  # Using these shared spec requires you to set the inst var @data_store

  describe "store" do
    it "should return a unique identifier for each storage" do
      @data_store.store('eggbert').should_not == @data_store.store('eggbert')
    end
  end
  
  describe "retrieve" do
    it "should retrieve the stored data" do
      id = @data_store.store('gollum')
      @data_store.retrieve(id).should == 'gollum'
    end

    it "should raise an exception if the data doesn't exist" do
      lambda{
        @data_store.retrieve('gooble/gubbub')
      }.should raise_error(Imagetastic::DataStorage::DataNotFound)
    end
  end

end