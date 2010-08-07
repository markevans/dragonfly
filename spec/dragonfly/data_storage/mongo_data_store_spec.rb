require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'
require 'mongo'

describe Dragonfly::DataStorage::MongoDataStore do
  
  before(:each) do
    begin
      Mongo::Connection.new
    rescue Mongo::ConnectionFailure => e
      pending "You need to start mongo on localhost:27017 to test the MongoDataStore"
    end
    @data_store = Dragonfly::DataStorage::MongoDataStore.new
  end
  
  it_should_behave_like 'data_store'

end
