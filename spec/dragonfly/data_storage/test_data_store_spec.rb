require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'

describe Dragonfly::DataStorage::TestDataStore do
  
  before(:each) do
    @data_store = Dragonfly::DataStorage::TestDataStore.new
  end
  
  it_should_behave_like 'data_store'

end
