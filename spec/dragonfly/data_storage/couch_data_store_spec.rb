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

  let (:app) { test_app }
  let (:content) { Dragonfly::Content.new(app, "gollum") }
  let (:new_content) { Dragonfly::Content.new(app) }

  describe "destroy" do
    it "should raise an error if the data doesn't exist on destroy" do
      uid = @data_store.store(content)
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

    it "serves with the correct data type (taken from ext)" do
      content.name = 'doogie.png'
      uid = @data_store.store(content)
      response = get_content(@data_store.url_for(uid))
      response.body.should == 'gollum'
      response['Content-Type'].should == 'image/png'
    end

 end

  describe "already stored stuff" do
    def store_pdf(meta)
      doc = CouchRest::Document.new(:meta => meta)
      doc_id = @data_store.db.save_doc(doc)['id']
      doc.put_attachment("pdf", "PDF data here")
      doc_id
    end

    it "still works" do
      doc_id = store_pdf('some' => 'cool things')
      @data_store.retrieve(new_content, "#{doc_id}/pdf")
      new_content.data.should == "PDF data here"
      new_content.meta['some'].should == 'cool things'
    end

    it "still works when meta was stored as a marshal dumped hash (but stringifies its keys)" do
      doc_id = store_pdf(Dragonfly::Serializer.marshal_b64_encode(:some => 'shizzle'))
      @data_store.retrieve(new_content, "#{doc_id}/pdf")
      new_content.meta['some'].should == 'shizzle'
    end
  end

end
