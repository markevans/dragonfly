require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'yaml'

describe Dragonfly::DataStorage::S3DataStore do

  # To run these tests, put a file ".s3_spec.yml" in the dragonfly root dir, like this:
  # key: XXXXXXXXXX
  # secret: XXXXXXXXXX
  # enabled: true
  if File.exist?(file = File.expand_path('../../../../.s3_spec.yml', __FILE__))
    config = YAML.load_file(file)
    KEY = config['key']
    SECRET = config['secret']
    enabled = config['enabled']
  else
    enabled = false
  end


  # Make sure it's a new bucket name
  BUCKET_NAME = "dragonfly-test-#{Time.now.to_i.to_s(36)}"

  if enabled

    before(:each) do
      WebMock.allow_net_connect!
      @data_store = Dragonfly::DataStorage::S3DataStore.new
      @data_store.configure do |d|
        d.bucket_name = BUCKET_NAME
        d.access_key_id = KEY
        d.secret_access_key = SECRET
        d.region = 'eu-west-1'
      end
    end
    
  else

    before(:each) do
      Fog.mock!
      @data_store = Dragonfly::DataStorage::S3DataStore.new
      @data_store.configure do |d|
        d.bucket_name = 'test-bucket'
        d.access_key_id = 'XXXXXXXXX'
        d.secret_access_key = 'XXXXXXXXX'
        d.region = 'eu-west-1'
      end
    end
    
  end

  it_should_behave_like 'data_store'

  describe "store" do
    it "should return a unique identifier for each storage" do
      temp_object = Dragonfly::TempObject.new('gollum')
      temp_object2 = Dragonfly::TempObject.new('gollum')
      @data_store.store(temp_object).should_not == @data_store.store(temp_object2)
    end

    it "should use the name in the meta if set" do
      temp_object = Dragonfly::TempObject.new('eggheads')
      uid = @data_store.store(temp_object, :meta => {:name =>  'doobie'})
      uid.should =~ /doobie$/
      data, meta = @data_store.retrieve(uid)
      data.should == 'eggheads'
    end

    it "should work ok with files with funny names" do
      temp_object = Dragonfly::TempObject.new('eggheads')
      uid = @data_store.store(temp_object, :meta => {:name =>  'A Picture with many spaces in its name (at 20:00 pm).png'})
      uid.should =~ /A_Picture_with_many_spaces_in_its_name_at_20_00_pm_\.png$/
      data, meta = @data_store.retrieve(uid)
      data.should == 'eggheads'
    end

    it "should allow for setting the path manually" do
      temp_object = Dragonfly::TempObject.new('eggheads')
      uid = @data_store.store(temp_object, :path => 'hello/there')
      uid.should == 'hello/there'
      data, meta = @data_store.retrieve(uid)
      data.should == 'eggheads'
    end
    
    it "should work fine when not using the filesystem" do
      @data_store.use_filesystem = false
      temp_object = Dragonfly::TempObject.new('gollum')
      uid = @data_store.store(temp_object)
      @data_store.retrieve(uid).first.should == "gollum"
    end
  end

  describe "destroy" do

    if enabled # Fog.mock doesn't seem to be consistent here with real one
      it "should raise not found if not found" do
        lambda {
          @data_store.destroy('some-random-egg')
        }.should raise_error(Dragonfly::DataStorage::DataNotFound)
      end
    end
    
  end

  describe "domain" do
    it "should default to the US" do
      @data_store.region = nil
      @data_store.domain.should == 's3.amazonaws.com'
    end
    
    it "should return the correct domain" do
      @data_store.region = 'eu-west-1'
      @data_store.domain.should == 's3-eu-west-1.amazonaws.com'
    end
    
    it "does raise an error if an unknown region is given" do
      @data_store.region = 'latvia-central'
      lambda{
        @data_store.domain
      }.should raise_error
    end
  end

  describe "not configuring stuff properly" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new("Hi guys")
    end
    
    it "should require a bucket name on store" do
      @data_store.bucket_name = nil
      proc{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
    
    it "should require an access_key_id on store" do
      @data_store.access_key_id = nil
      proc{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
    
    it "should require a secret access key on store" do
      @data_store.secret_access_key = nil
      proc{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
    
    it "should require a bucket name on retrieve" do
      @data_store.bucket_name = nil
      proc{ @data_store.retrieve('asdf') }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
    
    it "should require an access_key_id on retrieve" do
      @data_store.access_key_id = nil
      proc{ @data_store.retrieve('asdf') }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
    
    it "should require a secret access key on retrieve" do
      @data_store.secret_access_key = nil
      proc{ @data_store.retrieve('asdf') }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
  end

  describe "autocreating the bucket" do
    it "should create the bucket on store if it doesn't exist" do
      @data_store.bucket_name = "dragonfly-test-blah-blah-#{rand(100000000)}"
      @data_store.store(Dragonfly::TempObject.new("asdfj"))
    end
    
    it "should not try to create the bucket on retrieve if it doesn't exist" do
      @data_store.bucket_name = "dragonfly-test-blah-blah-#{rand(100000000)}"
      @data_store.send(:storage).should_not_receive(:put_bucket)
      proc{ @data_store.retrieve("gungle") }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end

end
