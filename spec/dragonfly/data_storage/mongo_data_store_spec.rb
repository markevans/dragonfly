# encoding: utf-8
require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'mongo'

describe Dragonfly::DataStorage::MongoDataStore do

  before(:each) do
    begin
      Mongo::Connection.new
    rescue Mongo::ConnectionFailure => e
      pending "You need to start mongo on localhost:27017 to test the MongoDataStore"
    end
    @data_store = Dragonfly::DataStorage::MongoDataStore.new :database => 'dragonfly_test'
  end

  it_should_behave_like 'data_store'

  describe "connecting to a replica set" do
    it "should initiate a replica set connection if hosts is set" do
      @data_store.hosts = ['1.2.3.4:27017', '1.2.3.4:27017']
      @data_store.connection_opts = {:name => 'testingset'}
      Mongo::ReplSetConnection.should_receive(:new).with(['1.2.3.4:27017', '1.2.3.4:27017'], :name => 'testingset')
      @data_store.connection
    end
  end
  
  describe "authenticating" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('Feijão verde')
    end

    it "should not attempt to authenticate if a username is not given" do
      @data_store.db.should_not_receive(:authenticate)
      @data_store.store(@temp_object)
    end

    it "should attempt to authenticate once if a username is given" do
      @data_store.username = 'terry'
      @data_store.password = 'butcher'
      @data_store.db.should_receive(:authenticate).exactly(:once).with('terry','butcher').and_return(true)
      uid = @data_store.store(@temp_object)
      @data_store.retrieve(uid)
    end
  end

  describe "sharing already configured stuff" do
    before(:each) do
      @connection = Mongo::Connection.new
      @temp_object = Dragonfly::TempObject.new('asdf')
    end

    it "should allow sharing the connection" do
      @data_store.connection = @connection
      @connection.should_receive(:db).with('dragonfly_test').and_return(db=mock)
      @data_store.db.should == db
    end

    it "should allow sharing the db" do
      db = @connection.db('dragonfly_test_yo')
      @data_store.db = db
      @data_store.grid.instance_eval{@db}.should == db # so wrong
    end
  end

  describe "extra options" do

    before(:each) do
      @temp_object = Dragonfly::TempObject.new('testingyo')
    end

    [:content_type, :mime_type].each do |key|
      it "should allow setting content type on store with #{key.inspect}" do
        uid = @data_store.store(@temp_object, key => 'text/plain')
        @data_store.grid.get(BSON::ObjectId(uid)).content_type.should == 'text/plain'
        @data_store.grid.get(BSON::ObjectId(uid)).read.should == 'testingyo'
      end
    end
  end

end
