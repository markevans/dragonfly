require 'dragonfly/content'
require 'dragonfly/data_storage'

shared_examples_for "data_store" do

  # Using these shared spec requires you to set the inst var @data_store
  let (:app) { Dragonfly.app }
  let (:content) { Dragonfly::Content.new(app, "gollum") }
  let (:content2) { Dragonfly::Content.new(app, "gollum") }


  describe "store" do
    it "returns a unique identifier for each storage" do
      @data_store.store(content).should_not == @data_store.store(content2)
    end
    it "should return a unique identifier for each storage even when the first is deleted" do
      uid1 = @data_store.store(content)
      @data_store.destroy(uid1)
      uid2 = @data_store.store(content)
      uid1.should_not == uid2
    end
    it "should allow for passing in options as a second argument" do
      @data_store.store(content, :some => :option)
    end
  end

  describe "retrieve" do
    before(:each) do
      content.add_meta('bitrate' => 35, 'name' => 'danny.boy')
      uid = @data_store.store(content)
      @retrieved_content = Dragonfly::Content.new(app)
      @data_store.retrieve(@retrieved_content, uid)
    end

    it "should retrieve the stored data" do
      @retrieved_content.data.should == "gollum"
    end

    it "should return the stored meta" do
      @retrieved_content.meta['bitrate'].should == 35
      @retrieved_content.meta['name'].should == 'danny.boy'
    end

    it "should raise an exception if the data doesn't exist" do
      lambda{
        @data_store.retrieve(Dragonfly::Content.new(app), 'gooble/gubbub')
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end

  describe "destroy" do

    it "should destroy the stored data" do
      uid = @data_store.store(content)
      @data_store.destroy(uid)
      lambda{
        @data_store.retrieve(Dragonfly::Content.new(app), uid)
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end

  end

end

