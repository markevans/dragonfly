# encoding: utf-8
require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'net/http'
require 'uri'

describe Dragonfly::DataStorage::CouchDataStore do

  before(:each) do
    WebMock.allow_net_connect!
    @data_store = Dragonfly::DataStorage::CouchDataStore.new(
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
  
  describe "destroy" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new('gollum')
    end
    
    it "should raise an error if the data doesn't exist on destroy" do
      uid = @data_store.store(@temp_object)
      @data_store.destroy(uid)
      lambda{
        @data_store.destroy(uid)
      }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end
  
  describe "url_for" do
    it "should give the correct url" do
      @data_store.url_for('asd7fas9df/thing.txt').should == 'http://localhost:5984/dragonfly_test/asd7fas9df/thing.txt'
    end
    
    it "should assume the attachment is called 'file' if not given" do
      @data_store.url_for('asd7fas9df').should == 'http://localhost:5984/dragonfly_test/asd7fas9df/file'
    end
  end
  
  describe "serving from couchdb" do

    def get_content(url)
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port) {|http|
        http.get(uri.path)
      }
    end

    before(:each) do
      @temp_object = Dragonfly::TempObject.new('testingyo')
    end
    
    it "should use the fallback by default" do
      uid = @data_store.store(@temp_object)
      response = get_content(@data_store.url_for(uid))
      response.body.should == 'testingyo'
      response['Content-Type'].should == 'application/octet-stream'
    end
    
    it "should allow setting on store with 'content_type'" do
      uid = @data_store.store(@temp_object, :content_type => 'text/plain')
      response = get_content(@data_store.url_for(uid))
      response.body.should == 'testingyo'
      response['Content-Type'].should == 'text/plain'
    end
    
    it "should allow setting on store with 'mime_type'" do
      uid = @data_store.store(@temp_object, :mime_type => 'text/plain-yo')
      response = get_content(@data_store.url_for(uid))
      response.body.should == 'testingyo'
      response['Content-Type'].should == 'text/plain-yo'
    end
  end
  
end
