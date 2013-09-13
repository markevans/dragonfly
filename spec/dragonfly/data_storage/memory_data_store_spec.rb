require 'spec_helper'
require 'dragonfly/spec/data_store_examples'

describe Dragonfly::DataStorage::MemoryDataStore do

  before(:each) do
    @data_store = Dragonfly::DataStorage::MemoryDataStore.new
  end

  it_should_behave_like 'data_store'

  it "allows setting the uid" do
    uid = @data_store.write(Dragonfly::Content.new(test_app, "Hello"), :uid => 'some_uid')
    uid.should == 'some_uid'
    content = Dragonfly::Content.new(test_app)
    @data_store.retrieve(content, uid)
    content.data.should == 'Hello'
  end

end

