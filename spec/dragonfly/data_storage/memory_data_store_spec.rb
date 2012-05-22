require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'

describe Dragonfly::DataStorage::MemoryDataStore do
  
  before(:each) do
    @data_store = Dragonfly::DataStorage::MemoryDataStore.new
  end
  
  it_should_behave_like 'data_store'

end
