# encoding: utf-8
require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'sqlite3'

describe Dragonfly::DataStorage::RelationalDataStore do

  before(:each) do
    setup_db
    @data_store = Dragonfly::DataStorage::RelationalDataStore.new
  end

  after(:each) do
    teardown_db
  end

  it_should_behave_like 'data_store'

end
