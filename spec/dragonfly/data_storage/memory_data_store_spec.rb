require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'

describe Dragonfly::DataStorage::MemoryDataStore do
  
  before(:each) do
    @data_store = Dragonfly::DataStorage::MemoryDataStore.new
  end
  
  it_should_behave_like 'data_store'

  it "allows setting the uid" do
    uid = @data_store.store(Dragonfly::TempObject.new("Hello"), :uid => 'some_uid')
    uid.should == 'some_uid'
    content, meta = @data_store.retrieve(uid)
    content.should == 'Hello'
  end

end
