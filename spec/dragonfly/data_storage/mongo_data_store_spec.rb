# encoding: utf-8
require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'mongo'

describe Dragonfly::DataStorage::MongoDataStore do

  let(:app) { test_app }
  let(:content) { Dragonfly::Content.new(app, "Pernumbucano") }
  let(:new_content) { Dragonfly::Content.new(app) }

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
    it "should not attempt to authenticate if a username is not given" do
      @data_store.db.should_not_receive(:authenticate)
      @data_store.store(content)
    end

    it "should attempt to authenticate once if a username is given" do
      @data_store.username = 'terry'
      @data_store.password = 'butcher'
      @data_store.db.should_receive(:authenticate).exactly(:once).with('terry','butcher').and_return(true)
      uid = @data_store.store(content)
      @data_store.retrieve(new_content, uid)
    end
  end

  describe "sharing already configured stuff" do
    before(:each) do
      @connection = Mongo::Connection.new
    end

    it "should allow sharing the connection" do
      data_store = Dragonfly::DataStorage::MongoDataStore.new :connection => @connection
      @connection.should_receive(:db).and_return(db=mock)
      data_store.db.should == db
    end

    it "should allow sharing the db" do
      db = @connection.db('dragonfly_test_yo')
      data_store = Dragonfly::DataStorage::MongoDataStore.new :db => db
      data_store.grid.instance_eval{@db}.should == db # so wrong
    end
  end

  describe "extra options" do
    [:content_type, :mime_type].each do |key|
      it "should allow setting content type on store with #{key.inspect}" do
        uid = @data_store.store(content, key => 'text/plain')
        @data_store.grid.get(BSON::ObjectId(uid)).content_type.should == 'text/plain'
        @data_store.grid.get(BSON::ObjectId(uid)).read.should == content.data
      end
    end
  end

  describe "already stored stuff" do
    it "still works" do
      uid = @data_store.grid.put("DOOBS", :metadata => {'some' => 'meta'}).to_s
      @data_store.retrieve(new_content, uid)
      new_content.data.should == "DOOBS"
      new_content.meta['some'].should == 'meta'
    end

    it "still works when meta was stored as a marshal dumped hash" do
      uid = @data_store.grid.put("DOOBS", :metadata => Dragonfly::Serializer.marshal_b64_encode('some' => 'stuff')).to_s
      @data_store.retrieve(new_content, uid)
      new_content.meta['some'].should == 'stuff'
    end
  end

end

