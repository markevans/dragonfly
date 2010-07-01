require File.dirname(__FILE__) + '/../spec_helper'

def dummy_rack_app
  lambda{|env| [200, {"Content-Type" => "text/plain"}, ["Hi everyone!"]] }
end

def make_request(app, url)
  Rack::MockRequest.new(app).get(url)
end

describe Dragonfly::DosProtector do

  before(:each) do
    @app = Rack::Builder.new do
      use Dragonfly::DosProtector, 'mysecret'
      run lambda{|env| [200, {"Content-Type" => "text/plain"}, ["Hi everyone!"]] }
    end
  end

  it "should return 400 with a message if no sha given" do
    response = make_request(@app, 'http://example.com/hello/there')
    response.status.should == 400
    response.body.should =~ /You need to give a SHA/
  end

  it "should return 400 with a message if sha given is incorrect" do
    response = make_request(@app, 'http://example.com/hello/there?s=sadfsadf')
    response.status.should == 400
    response.body.should =~ /The SHA parameter you gave is incorrect/
  end
  
  it "should pass through to the rest of the stack if sha is correct" do
    response = make_request(@app, 'http://example.com/hello/there?s=22d94173b7eb367142d433a034a9062ac1849c8f')
    response.status.should == 200
    response.body.should == "Hi everyone!"
  end

end
