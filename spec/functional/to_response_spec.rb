require 'spec_helper'

describe "getting rack response directly" do
  
  before(:each) do
    @app = test_app.configure do |c|
      c.generator.add :test do
        "bunheads"
      end
    end
  end
  
  it "should give a rack response" do
    response = @app.generate(:test, 1, 1).to_response
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 200
    response[1]['Content-Type'].should == 'application/octet-stream'
    response[2].data.should == 'bunheads'
  end
  
  it "should allow passing in the env" do
    response = @app.generate(:test, 1, 1).to_response('REQUEST_METHOD' => 'POST')
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 405
    response[1]['Content-Type'].should == 'text/plain'
    response[2].should == ["POST method not allowed"]
  end
  
end
