require 'spec_helper'

describe "remote on-the-fly urls" do

  before(:each) do
    @thumbs = thumbs = {}
    @app = test_app.configure do
      generator :test do |content|
        content.update("TEST")
      end
      before_serve do |job, env|
        uid = job.store(:path => 'yay.txt')
        thumbs[job.serialize] = uid
      end
      define_url do |app, job, opts|
        uid = thumbs[job.serialize]
        if uid
          app.datastore.url_for(uid)
        else
          app.server.url_for(job)
        end
      end
      datastore :file,
        :root_path => 'tmp/dragonfly_test_urls',
        :server_root => 'tmp'
    end
    @job = @app.generate(:test)
  end

  after(:each) do
    FileUtils.rm_f('tmp/dragonfly_test_urls/yay.txt')
  end

  it "should give the url for the server" do
    @job.url.should == "/#{@job.serialize}?sha=#{@job.sha}"
  end

  it "should store the content when first called" do
    File.exist?('tmp/dragonfly_test_urls/yay.txt').should be_falsey
    request(@app, @job.url)
    File.read('tmp/dragonfly_test_urls/yay.txt').should == 'TEST'
  end

  it "should point to the external url the second time" do
    request(@app, @job.url)
    @job.url.should == '/dragonfly_test_urls/yay.txt'
  end

end
