require 'spec_helper'

shared_examples_for "data_store" do

  # Using these shared spec requires you to set the inst var @data_store

  before(:each) do
    @temp_object = Dragonfly::TempObject.new('gollum')
  end

  describe "store" do
    it "should return a unique identifier for each storage" do
      temp_object2 = Dragonfly::TempObject.new('gollum')
      @data_store.store(@temp_object).should_not == @data_store.store(temp_object2)
    end
    it "should return a unique identifier for each storage even when the first is deleted" do
      uid1 = @data_store.store(@temp_object)
      @data_store.destroy(uid1)
      uid2 = @data_store.store(@temp_object)
      uid1.should_not == uid2
    end
    it "should allow for passing in options as a second argument" do
      @data_store.store(@temp_object, :some => :option)
    end
  end

  describe "retrieve" do

    describe "without meta" do
      before(:each) do
        uid = @data_store.store(@temp_object)
        @obj, @meta = @data_store.retrieve(uid)
      end

      it "should retrieve the stored data" do
        Dragonfly::TempObject.new(@obj).data.should == @temp_object.data
      end
      
      it "should return a meta hash (probably empty)" do
        @meta.should be_a(Hash)
      end

    end

    describe "when meta is given" do
      before(:each) do
        temp_object = Dragonfly::TempObject.new('gollum', :bitrate => '35', :name => 'danny.boy')
        @uid = @data_store.store(temp_object)
        @obj, @meta = @data_store.retrieve(@uid)
      end

      it "should return the stored meta" do
        @meta[:bitrate].should == '35'
        @meta[:name].should == 'danny.boy'
      end
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

  end

end
