# encoding: utf-8
require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'net/http'

describe Dragonfly::DataStorage::CouchDataStore do

  before(:each) do
    WebMock.allow_net_connect!
    @data_store = Dragonfly::DataStorage::CouchDataStore.new(
      :host => "localhost", 
      :port => "5984", 
      :username => "", 
      :password => "", 
      :database => "dragonfly_test"
    )
    begin
      @data_store.db.get('ping')
    rescue Errno::ECONNREFUSED => e
      pending "You need to start CouchDB on localhost:5984 to test the CouchDataStore"
    rescue RestClient::ResourceNotFound
    end
    
  end
  
  it_should_behave_like 'data_store'
  
  describe "serving from couchdb" do

    def get_content(uid, name)
      Net::HTTP.start('localhost', 5984) {|http|
        http.get("/dragonfly_test/#{uid}/#{name}")
      }
    end

    before(:each) do
      @temp_object = Dragonfly::TempObject.new('testingyo')
    end

    it "should serve using the format of the filename" do
      pending
    end
    
    it "should use the fallback if it has no ext" do
      pending
    end
    
    it "should use the fallback by default" do
      uid = @data_store.store(@temp_object)
      response = get_content(uid, 'file')
      response.body.should == 'testingyo'
      response['Content-Type'].should == 'application/octet-stream'
    end
    
    it "should allow setting on store with 'content_type'" do
      uid = @data_store.store(@temp_object, :content_type => 'text/plain')
      response = get_content(uid, 'file')
      response.body.should == 'testingyo'
      response['Content-Type'].should == 'text/plain'
    end
    
    it "should allow setting on store with 'mime_type'" do
      uid = @data_store.store(@temp_object, :mime_type => 'text/plain-yo')
      response = get_content(uid, 'file')
      response.body.should == 'testingyo'
      response['Content-Type'].should == 'text/plain-yo'
    end
  end
  
end
