require 'spec_helper'

describe "remote on-the-fly urls" do
  
  THUMBS = {}
  
  before(:each) do
    @app = test_app.configure do |c|
      c.generator.add :test do
        "TEST"
      end
      c.server.before_serve do |job, env|
        uid = job.store(:path => 'yay.txt')
        THUMBS[job.serialize] = uid
      end
      c.define_url do |app, job, opts|
        uid = THUMBS[job.serialize]
        if uid
          app.datastore.url_for(uid)
        else
          app.server.url_for(job)
        end
      end
      c.datastore = Dragonfly::DataStorage::FileDataStore.new
      c.datastore.root_path = 'tmp/dragonfly_test_urls'
      c.datastore.server_root = 'tmp'
    end
    @job = @app.generate(:test)
  end

  after(:each) do
    THUMBS.delete_if{true}
    FileUtils.rm_f('tmp/dragonfly_test_urls/yay.txt')
  end
  
  it "should give the url for the server" do
    @job.url.should == "/#{@job.serialize}"
  end
  
  it "should store the content when first called" do
    File.exist?('tmp/dragonfly_test_urls/yay.txt').should be_false
    @app.server.call('PATH_INFO' => @job.url, 'REQUEST_METHOD' => 'GET')
    File.read('tmp/dragonfly_test_urls/yay.txt').should == 'TEST'
  end

  it "should point to the external url the second time" do
    @app.server.call('PATH_INFO' => @job.url, 'REQUEST_METHOD' => 'GET')
    @job.url.should == '/dragonfly_test_urls/yay.txt'
  end

end
