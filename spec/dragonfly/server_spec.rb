require 'spec_helper'
require 'rack/mock'
require 'rack/cache'

def request(app, path)
  Rack::MockRequest.new(app).get(path)
end

describe Dragonfly::Server do

  before(:each) do
    @app = test_app
    @uid = @app.store('HELLO THERE')
    @endpoint = Dragonfly::Server.new(@app)
    @endpoint.url_format = '/media/:job'
    @job = @app.fetch(@uid)
  end
  
  after(:each) do
    @app.destroy(@uid)
  end

  it "should return the thing when given the url" do
    url = "/media/#{@job.serialize}"
    response = request(@endpoint, url)
    response.status.should == 200
    response.body.should == 'HELLO THERE'
    response.content_type.should == 'application/octet-stream'
  end

  it "should return a 400 if no sha given but protection on" do
    @endpoint.protect_from_dos_attacks = true
    url = "/media/#{@job.serialize}"
    response = request(@endpoint, url)
    response.status.should == 400
  end
  
  it "should return a 400 if wrong sha given and protection on" do
    @endpoint.protect_from_dos_attacks = true
    url = "/media/#{@job.serialize}?sha=asdfs"
    response = request(@endpoint, url)
    response.status.should == 400
  end
  
  it "should return a 404 when the url matches but doesn't correspond to a job" do
    response = request(@endpoint, '/media/sadhfasdfdsfsdf')
    response.status.should == 404
    response.body.should == 'Not found'
    response.content_type.should == 'text/plain'
    response.headers['X-Cascade'].should be_nil
  end
  
  it "should return a 404 when the url isn't known at all" do
    response = request(@endpoint, '/jfasd/dsfa')
    response.status.should == 404
    response.body.should == 'Not found'
    response.content_type.should == 'text/plain'
    response.headers['X-Cascade'].should == 'pass'
  end
  
  it "should return a 404 when the url is a well-encoded but bad array" do
    url = "/media/#{Dragonfly::Serializer.marshal_encode([[:egg, {:some => 'args'}]])}"
    response = request(@endpoint, url)
    response.status.should == 404
    response.body.should == 'Not found'
    response.content_type.should == 'text/plain'
    response.headers['X-Cascade'].should be_nil
  end

  # it "should return a simple text response at the root" do
  #   response = request(@endpoint, '/')
  #   response.status.should == 200
  #   response.body.length.should > 0
  #   response.content_type.should == 'text/plain'
  # end

  it "should return a cacheable response" do
    url = "/media/#{@job.serialize}"
    cache = Rack::Cache.new(@endpoint, :entitystore => 'heap:/')
    response = request(cache, url)
    response.status.should == 200
    response.headers['X-Rack-Cache'].should == "miss, store"
    response = request(cache, url)
    response.status.should == 200
    response.headers['X-Rack-Cache'].should == "fresh"
  end
end
