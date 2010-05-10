require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'

describe Dragonfly::DataStorage::S3DataStore do

  # Uncomment this to test it with an actual internet connection
  # describe "common data_store behaviour" do
  #   
  #   before(:each) do
  #     @data_store = Dragonfly::DataStorage::S3DataStore.new
  #     @data_store.configure do |d|
  #       d.bucket_name = 'dragonfly_test'
  #       d.access_key_id = 'xxxxxxxxxx'
  #       d.secret_access_key = 'xxxxxxxxxx'
  #     end
  #   end
  #   
  #   it_should_behave_like 'data_store'
  #   
  # end

  describe "specific s3_data_store behaviour" do
    before(:each) do
      @data_store = Dragonfly::DataStorage::S3DataStore.new
      @data_store.configure do |d|
        d.bucket_name = 'dragonfly_test'
        d.access_key_id = 'my_key_id'
        d.secret_access_key = 'my_secret_access_key'
      end
      @temp_object = Dragonfly::TempObject.new('gollum')
      AWS::S3::Base.stub!(:establish_connection!).with(
        :access_key_id => @data_store.access_key_id,
        :secret_access_key => @data_store.secret_access_key
      )
      AWS::S3::Bucket.stub!(:create).with(@data_store.bucket_name)
      AWS::S3::Service.stub!(:buckets).and_return([])
      AWS::S3::S3Object.stub!(:store).with(anything, anything, @data_store.bucket_name)
      AWS::S3::S3Object.stub!(:value).with(anything, @data_store.bucket_name)
      AWS::S3::S3Object.stub!(:delete).with(anything, @data_store.bucket_name)
    end
    

    describe "store" do
      it "should return a unique identifier for each storage" do
        temp_object2 = Dragonfly::TempObject.new('gollum')
        @data_store.store(@temp_object).should_not == @data_store.store(temp_object2)
      end
    end
  end

end