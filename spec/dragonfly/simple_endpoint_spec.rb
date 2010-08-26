require File.dirname(__FILE__) + '/../spec_helper'
require 'rack/mock'
require 'rack/cache'

def request(app, path)
  Rack::MockRequest.new(app).get(path)
end

describe Dragonfly::SimpleEndpoint do

  before(:each) do
    @app = test_app
    @app.protect_from_dos_attacks = false
    @uid = @app.store('HELLO THERE')
    @endpoint = Dragonfly::SimpleEndpoint.new(@app)
  end
  
  after(:each) do
    @app.destroy(@uid)
  end

  it "should return the thing when given the url" do
    url = "/#{@app.fetch(@uid).serialize}"
    response = request(@endpoint, url)
    response.status.should == 200
    response.body.should == 'HELLO THERE'
    response.content_type.should == 'application/octet-stream'
  end

  it "should return a 400 if no sha given but protection on" do
    @app.protect_from_dos_attacks = true
    url = "/#{@app.fetch(@uid).serialize}"
    response = request(@endpoint, url)
    response.status.should == 400
  end
  
  it "should return a 400 if wrong sha given and protection on" do
    @app.protect_from_dos_attacks = true
    url = "/#{@app.fetch(@uid).serialize}?s=asdfs"
    response = request(@endpoint, url)
    response.status.should == 400
  end
  
  it "should return a 404 when the url isn't known" do
    response = request(@endpoint, '/sadhfasdfdsfsdf')
    response.status.should == 404
    response.body.should == 'Not found'
    response.content_type.should == 'text/plain'
  end
  
  it "should return a 404 when the url is a well-encoded but bad array" do
    url = "/#{Dragonfly::Serializer.marshal_encode([[:egg, {:some => 'args'}]])}"
    response = request(@endpoint, url)
    response.status.should == 404
    response.body.should == 'Not found'
    response.content_type.should == 'text/plain'
  end

  it "should still work when mapped to a prefix" do
    endpoint = @endpoint
    rack_app = Rack::Builder.new do
      map '/some_prefix' do
        run endpoint
      end
    end.to_app
    url = "/some_prefix/#{@app.fetch(@uid).serialize}"
    response = request(rack_app, url)
    response.status.should == 200
    response.body.should == 'HELLO THERE'
  end

  it "should return a simple text response at the root" do
    response = request(@endpoint, '/')
    response.status.should == 200
    response.body.length.should > 0
    response.content_type.should == 'text/plain'
  end

  it "should return a cacheable response" do
    url = "/#{@app.fetch(@uid).serialize}"
    cache = Rack::Cache.new(@endpoint, :entitystore => 'heap:/')
    response = request(cache, url)
    response.status.should == 200
    response.headers['X-Rack-Cache'].should == "miss, store"
    response = request(cache, url)
    response.status.should == 200
    response.headers['X-Rack-Cache'].should == "fresh"
  end
end
