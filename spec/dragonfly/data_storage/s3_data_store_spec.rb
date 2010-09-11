require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/data_store_spec'
require 'yaml'

describe Dragonfly::DataStorage::S3DataStore do

  # Change this to test it with an actual internet connection
  if File.exist?(file = File.expand_path('../../../../.s3_spec.yml', __FILE__))
    config = YAML.load_file(file)
    KEY = config['key']
    SECRET = config['secret']
    enabled = config['enabled']
  else
    enabled = false
  end

  if enabled

    describe "common data_store behaviour" do

      before(:each) do
        @data_store = Dragonfly::DataStorage::S3DataStore.new
        @data_store.configure do |d|
          d.bucket_name = 'dragonfly_test'
          d.access_key_id = KEY
          d.secret_access_key = SECRET
        end
      end

      it_should_behave_like 'data_store'

      describe "store" do
        it "should return a unique identifier for each storage" do
          temp_object = Dragonfly::TempObject.new('gollum')
          temp_object2 = Dragonfly::TempObject.new('gollum')
          @data_store.store(temp_object).should_not == @data_store.store(temp_object2)
        end

        it "should work ok with files with funny names" do
          temp_object = Dragonfly::TempObject.new('eggheads',
            :name =>  'A Picture with many spaces in its name (at 20:00 pm).png'
          )
          uid = @data_store.store(temp_object)
          uid.should =~ /A_Picture_with_many_spaces_in_its_name_at_20_00_pm_\.png$/
          data, extra = @data_store.retrieve(uid)
          data.should == 'eggheads'
        end

        it "should allow for setting the path manually" do
          temp_object = Dragonfly::TempObject.new('eggheads')
          uid = @data_store.store(temp_object, :path => 'hello/there')
          uid.should == 'hello/there'
          data, extra = @data_store.retrieve(uid)
          data.should == 'eggheads'
        end
      end

    end

  end

end
