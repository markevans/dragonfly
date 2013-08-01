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

  if enabled

    # Make sure it's a new bucket name
    BUCKET_NAME = "dragonfly-test-#{Time.now.to_i.to_s(36)}"

    before(:each) do
      WebMock.allow_net_connect!
      @data_store = Dragonfly::DataStorage::S3DataStore.new(
        :bucket_name => BUCKET_NAME,
        :access_key_id => KEY,
        :secret_access_key => SECRET,
        :region => 'eu-west-1'
      )
    end

  else

    BUCKET_NAME = 'test-bucket'

    before(:each) do
      Fog.mock!
      @data_store = Dragonfly::DataStorage::S3DataStore.new(
        :bucket_name => BUCKET_NAME,
        :access_key_id => 'XXXXXXXXX',
        :secret_access_key => 'XXXXXXXXX',
        :region => 'eu-west-1'
      )
    end

  end

  it_should_behave_like 'data_store'

  let (:app) { test_app }
  let (:content) { Dragonfly::Content.new(app, "eggheads") }
  let (:new_content) { Dragonfly::Content.new(app) }

  describe "store" do
    it "should use the name from the content if set" do
      content.name = 'doobie.doo'
      uid = @data_store.store(content)
      uid.should =~ /doobie\.doo$/
      @data_store.retrieve(new_content, uid)
      new_content.data.should == 'eggheads'
    end

    it "should work ok with files with funny names" do
      content.name = "A Picture with many spaces in its name (at 20:00 pm).png"
      uid = @data_store.store(content)
      uid.should =~ /A_Picture_with_many_spaces_in_its_name_at_20_00_pm_\.png$/
      @data_store.retrieve(new_content, uid)
      new_content.data.should == 'eggheads'
    end

    it "should allow for setting the path manually" do
      uid = @data_store.store(content, :path => 'hello/there')
      uid.should == 'hello/there'
      @data_store.retrieve(new_content, uid)
      new_content.data.should == 'eggheads'
    end

    it "should work fine when not using the filesystem" do
      @data_store.use_filesystem = false
      uid = @data_store.store(content)
      @data_store.retrieve(new_content, uid)
      new_content.data.should == "eggheads"
    end

    if enabled # Fog.mock! doesn't act consistently here
      it "should reset the connection and try again if Fog throws a socket EOFError" do
        @data_store.storage.should_receive(:put_object).exactly(:once).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        @data_store.storage.should_receive(:put_object).with(BUCKET_NAME, anything, anything, hash_including)
        @data_store.store(content)
      end

      it "should just let it raise if Fog throws a socket EOFError again" do
        @data_store.storage.should_receive(:put_object).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        @data_store.storage.should_receive(:put_object).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        expect{
          @data_store.store(content)
        }.to raise_error(Excon::Errors::SocketError)
      end
    end
  end

  # Doesn't appear to raise anything right now
  # describe "destroy" do
  #   it "should raise an error if the data doesn't exist on destroy" do
  #     uid = @data_store.store(content)
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
    it "should require a bucket name on store" do
      @data_store.bucket_name = nil
      proc{ @data_store.store(content) }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end

    it "should require an access_key_id on store" do
      @data_store.access_key_id = nil
      proc{ @data_store.store(content) }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end

    it "should require a secret access key on store" do
      @data_store.secret_access_key = nil
      proc{ @data_store.store(content) }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end

    it "should require a bucket name on retrieve" do
      @data_store.bucket_name = nil
      proc{ @data_store.retrieve(new_content, 'asdf') }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end

    it "should require an access_key_id on retrieve" do
      @data_store.access_key_id = nil
      proc{ @data_store.retrieve(new_content, 'asdf') }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end

    it "should require a secret access key on retrieve" do
      @data_store.secret_access_key = nil
      proc{ @data_store.retrieve(new_content, 'asdf') }.should raise_error(Dragonfly::DataStorage::S3DataStore::NotConfigured)
    end
  end

  describe "autocreating the bucket" do
    it "should create the bucket on store if it doesn't exist" do
      @data_store.bucket_name = "dragonfly-test-blah-blah-#{rand(100000000)}"
      @data_store.store(content)
    end

    it "should not try to create the bucket on retrieve if it doesn't exist" do
      @data_store.bucket_name = "dragonfly-test-blah-blah-#{rand(100000000)}"
      @data_store.send(:storage).should_not_receive(:put_bucket)
      proc{ @data_store.retrieve(new_content, "gungle") }.should raise_error(Dragonfly::DataStorage::DataNotFound)
    end
  end

  describe "headers" do
    before(:each) do
      @data_store.storage_headers = {'x-amz-foo' => 'biscuithead'}
    end

    it "should allow configuring globally" do
      @data_store.storage.should_receive(:put_object).with(BUCKET_NAME, anything, anything,
        hash_including('x-amz-foo' => 'biscuithead')
      )
      @data_store.store(content)
    end

    it "should allow adding per-store" do
      @data_store.storage.should_receive(:put_object).with(BUCKET_NAME, anything, anything,
        hash_including('x-amz-foo' => 'biscuithead', 'hello' => 'there')
      )
      @data_store.store(content, :headers => {'hello' => 'there'})
    end

    it "should let the per-store one take precedence" do
      @data_store.storage.should_receive(:put_object).with(BUCKET_NAME, anything, anything,
        hash_including('x-amz-foo' => 'override!')
      )
      @data_store.store(content, :headers => {'x-amz-foo' => 'override!'})
    end

    it "should store with the content-type if passed in" do
      @data_store.storage.should_receive(:put_object) do |_, __, ___, headers|
        headers['Content-Type'].should == 'text/plain'
      end
      @data_store.store(content, :mime_type => 'text/plain')
    end
  end

  describe "urls for serving directly" do

    before(:each) do
      @uid = 'some/path/on/s3'
    end

    it "should use the bucket subdomain" do
      @data_store.url_for(@uid).should == "http://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should use the bucket subdomain for other regions too" do
      @data_store.region = 'eu-west-1'
      @data_store.url_for(@uid).should == "http://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should give an expiring url" do
      @data_store.url_for(@uid, :expires => 1301476942).should =~
        %r{^https://#{BUCKET_NAME}\.#{@data_store.domain}/some/path/on/s3\?AWSAccessKeyId=#{@data_store.access_key_id}&Signature=[\w%]+&Expires=1301476942$}
    end

    it "should allow for using https" do
      @data_store.url_for(@uid, :scheme => 'https').should == "https://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should allow for always using https" do
      @data_store.url_scheme = 'https'
      @data_store.url_for(@uid).should == "https://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should allow for customizing the host" do
      @data_store.url_for(@uid, :host => 'customised.domain.com/and/path').should == "http://customised.domain.com/and/path/some/path/on/s3"
    end

    it "should allow the url_host to be customised permanently" do
      url_host = 'customised.domain.com/and/path'
      @data_store.url_host = url_host
      @data_store.url_for(@uid).should == "http://#{url_host}/some/path/on/s3"
    end

  end

  describe "meta" do
    it "adds any x-amz-meta- headers to the meta" do
      uid = @data_store.store(content, :headers => {'x-amz-meta-potato' => 'zanzibar'})
      @data_store.retrieve(new_content, uid)
      new_content.meta['potato'].should == 'zanzibar'
    end

    it "works with the deprecated x-amz-meta-extra header (but stringifies its keys)" do
      uid = @data_store.store(content, :headers => {'x-amz-meta-extra' => Dragonfly::Serializer.marshal_b64_encode(:some => 'meta', :wo => 4)})
      @data_store.retrieve(new_content, uid)
      new_content.meta['some'].should == 'meta'
      new_content.meta['wo'].should == 4
    end
  end

end
