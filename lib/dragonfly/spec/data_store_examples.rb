require 'dragonfly/content'

shared_examples_for "data_store" do

  # Using these shared spec requires you to set the inst var @data_store
  let (:app) { Dragonfly.app }
  let (:content) { Dragonfly::Content.new(app, "gollum") }
  let (:content2) { Dragonfly::Content.new(app, "gollum") }


  describe "write" do
    it "returns a unique identifier for each storage" do
      @data_store.write(content).should_not == @data_store.write(content2)
    end
    it "should return a unique identifier for each storage even when the first is deleted" do
      uid1 = @data_store.write(content)
      @data_store.destroy(uid1)
      uid2 = @data_store.write(content)
      uid1.should_not == uid2
    end
    it "should allow for passing in options as a second argument" do
      @data_store.write(content, :some => :option)
    end
  end

  describe "read" do
    before(:each) do
      content.add_meta('bitrate' => 35, 'name' => 'danny.boy')
      uid = @data_store.write(content)
      stuff, meta = @data_store.read(uid)
      @retrieved_content = Dragonfly::Content.new(app, stuff, meta)
    end

    it "should read the stored data" do
      @retrieved_content.data.should == "gollum"
    end

    it "should return the stored meta" do
      @retrieved_content.meta['bitrate'].should == 35
      @retrieved_content.meta['name'].should == 'danny.boy'
    end

    it "should return nil if the data doesn't exist" do
      @data_store.read('gooble').should be_nil
    end
  end

  describe "destroy" do

    it "should destroy the stored data" do
      uid = @data_store.write(content)
      @data_store.destroy(uid)
      @data_store.read(uid).should be_nil
    end

    it "should do nothing if the data doesn't exist on destroy" do
      uid = @data_store.write(content)
      @data_store.destroy(uid)
      @data_store.destroy(uid)
    end

  end

end
