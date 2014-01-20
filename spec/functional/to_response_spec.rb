require 'spec_helper'

describe "getting rack response directly" do

  before(:each) do
    @app = test_app.configure do
      generator :test do |content|
        content.update("bunheads")
      end
    end
  end

  it "should give a rack response" do
    response = @app.generate(:test).to_response
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 200
    response[1]['Content-Type'].should == 'application/octet-stream'
    response[2].data.should == 'bunheads'
  end

  it "should give a rack response for resuming downloads" do
    response = @app.generate(:test).to_response('REQUEST_METHOD' => 'GET', 'HTTP_RANGE' => 'bytes=3-')
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 206
    response[1]['Content-Type'].should == 'application/octet-stream'
    response[1]['Content-Length'].should == "5"
    response[1]['Content-Range'].should == "bytes 3-7/8"
    response[1]['Cache-Control'].should == "public, must-revalidate, max-age=0"
    response[1]['Pragma'].should == "no-cache"
    response[1]['Accept-Ranges'].should == "bytes"
    response[2].each do |x|
      x.should == "heads"
    end
  end

  it "should give a rack response for resuming downloads where the range is totally messed up" do
    response = @app.generate(:test).to_response('REQUEST_METHOD' => 'GET', 'HTTP_RANGE' => 'bytes=1337-0')
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 206
    response[1]['Content-Type'].should == 'application/octet-stream'
    response[1]['Content-Length'].should == "8"
    response[1]['Content-Range'].should == "bytes 0-7/8"
    response[2].each do |x|
      x.should == "bunheads"
    end
  end

  it "should give a rack response for resuming downloads where the range is partially messed up" do
    response = @app.generate(:test).to_response('REQUEST_METHOD' => 'GET', 'HTTP_RANGE' => 'bytes=1337-')
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 206
    response[1]['Content-Type'].should == 'application/octet-stream'
    response[1]['Content-Length'].should == "8"
    response[1]['Content-Range'].should == "bytes 0-7/8"
    response[2].each do |x|
      x.should == "bunheads"
    end
  end

  it "should allow passing in the env" do
    response = @app.generate(:test).to_response('REQUEST_METHOD' => 'POST')
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 405
    response[1]['Content-Type'].should == 'text/plain'
    response[2].should == ["method not allowed"]
  end

end
