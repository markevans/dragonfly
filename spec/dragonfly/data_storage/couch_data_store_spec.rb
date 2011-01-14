# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'
require 'couchrest'

describe Dragonfly::DataStorage::CouchDataStore do
  before(:each) do
    @data_store = Dragonfly::DataStorage::CouchDataStore.new(
      :host => "localhost", 
      :port => "5984", 
      :username => "", 
      :password => "", 
      :database => "dragonfly_test"
    )
  end
  
  it_should_behave_like 'data_store'  
end
