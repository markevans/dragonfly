require 'spec_helper'
require File.dirname(__FILE__) + '/shared_data_store_examples'
require 'yaml'

describe Dragonfly::DataStorage::CloudfilesDataStore do

  # To run these tests, put a file ".cloudfiles_spec.yml" in the dragonfly root dir, like this:
  # key: XXXXXXXXXX
  # username: XXXXXXXXXX
  # enabled: true
  if File.exist?(file = File.expand_path('../../../../.cloudfiles_spec.yml', __FILE__))
    config = YAML.load_file(file)
    KEY = config['key']
    USERNAME = config['username']
    enabled = config['enabled']
  else
    enabled = false
  end

  if enabled

    # Make sure it's a new directory
    DIRECTORY = "dragonfly-test-#{Time.now.to_i.to_s(36)}"

    before(:each) do
      WebMock.allow_net_connect!
      @data_store = Dragonfly::DataStorage::CloudfilesDataStore.new
      @data_store.configure do |d|
        d.directory = DIRECTORY
        d.key_id = KEY
        d.username = USERNAME
      end
    end
    
  else

    DIRECTORY = 'test-directory'
    KEY='123'
    USERNAME='123'

    before(:each) do
      Fog.mock!
      @data_store = Dragonfly::DataStorage::CloudfilesDataStore.new
      @data_store.configure do |d|
        d.directory = DIRECTORY
        d.key_id = KEY
        d.username = USERNAME
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
    
    if enabled # Fog.mock! doesn't act consistently here
      it "should reset the connection and try again if Fog throws a socket EOFError" do
        temp_object = Dragonfly::TempObject.new('gollum')
        @data_store.storage.should_receive(:put_object).exactly(:once).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        @data_store.storage.should_receive(:put_object).with(DIRECTORY, anything, anything, hash_including)
        @data_store.store(temp_object)
      end

      it "should just let it raise if Fog throws a socket EOFError again" do
        temp_object = Dragonfly::TempObject.new('gollum')
        @data_store.storage.should_receive(:put_object).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        @data_store.storage.should_receive(:put_object).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        expect{
          @data_store.store(temp_object)
        }.to raise_error(Excon::Errors::SocketError)
      end
    end
  end

  # Doesn't appear to raise anything right now
  # describe "destroy" do
  #   before(:each) do
  #     @temp_object = Dragonfly::TempObject.new('gollum')
  #   end
  #   it "should raise an error if the data doesn't exist on destroy" do
  #     uid = @data_store.store(@temp_object)
  #     @data_store.destroy(uid)
  #     lambda{
  #       @data_store.destroy(uid)
  #     }.should raise_error(Dragonfly::DataStorage::DataNotFound)
  #   end
  # end

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
    
    it "should require a directory on store" do
      @data_store.directory = nil
      proc{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::Configurable::NotConfigured)
    end
    
    it "should require an key_id on store" do
      @data_store.key_id = nil
      proc{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::Configurable::NotConfigured)
    end
    
    it "should require a username on store" do
      @data_store.username = nil
      proc{ @data_store.store(@temp_object) }.should raise_error(Dragonfly::Configurable::NotConfigured)
    end
    
    it "should require a directory on retrieve" do
      @data_store.directory = nil
      proc{ @data_store.retrieve('asdf') }.should raise_error(Dragonfly::Configurable::NotConfigured)
    end
    
    it "should require an key_id on retrieve" do
      @data_store.key_id = nil
      proc{ @data_store.retrieve('asdf') }.should raise_error(Dragonfly::Configurable::NotConfigured)
    end
    
    it "should require a username on retrieve" do
      @data_store.username = nil
      proc{ @data_store.retrieve('asdf') }.should raise_error(Dragonfly::Configurable::NotConfigured)
    end
  end

  describe "autocreating the directory" do
    it "should create the directory on store if it doesn't exist" do
      @data_store.directory = "dragonfly-test-blah-blah-#{rand(100000000)}"
      @data_store.store(Dragonfly::TempObject.new("asdfj"))
    end
    
    it "should not try to create the directory on retrieve if it doesn't exist" do
      @data_store.directory = "dragonfly-test-blah-blah-#{rand(100000000)}"
      @data_store.send(:storage).should_not_receive(:put_directory)
      proc{ @data_store.retrieve("gungle") }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end
  
  describe "urls for serving directly" do
    
    before(:each) do
      @uid = 'some/path/on/rackspace'
      @cdn_host = @data_store.cdn_host
    end
    
    it "should use the directory subdomain" do
      @data_store.url_for(@uid).should == "#{@cdn_host}/some/path/on/rackspace"
    end
    
    it "should use the directory subdomain for other regions too" do
      @data_store.region = 'eu-west-1'
      @data_store.url_for(@uid).should == "#{@cdn_host}/some/path/on/rackspace"
    end
  end

end
