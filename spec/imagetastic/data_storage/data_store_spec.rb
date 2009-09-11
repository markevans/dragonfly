require File.dirname(__FILE__) + '/../../spec_helper'

describe "data_store", :shared => true do

  # Using these shared spec requires you to set the inst var @data_store

  describe "store" do
    it "should return a unique identifier for each storage" do
      image = Imagetastic::Image.new('eggbert')
      @data_store.store(image).should_not == @data_store.store(image)
    end
  end
  
  describe "retrieve" do
    it "should retrieve the stored data" do
      image = Imagetastic::Image.new('gollum')
      id = @data_store.store(image)
      @data_store.retrieve(id).data.should == image.data
    end

    it "should raise an exception if the data doesn't exist" do
      lambda{
        @data_store.retrieve('gooble/gubbub')
      }.should raise_error(Imagetastic::DataStorage::DataNotFound)
    end
  end

end