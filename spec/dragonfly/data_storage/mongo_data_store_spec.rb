require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'

describe Dragonfly::DataStorage::MongoDataStore do
  
  before(:each) do
    @data_store = Dragonfly::DataStorage::MongoDataStore.new
  end
  
  after(:each) do
  end
  
  it_should_behave_like 'data_store'

end
