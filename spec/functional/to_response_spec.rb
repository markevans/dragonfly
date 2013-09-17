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

  it "should allow passing in the env" do
    response = @app.generate(:test).to_response('REQUEST_METHOD' => 'POST')
    response.should be_a(Array)
    response.length.should == 3
    response[0].should == 405
    response[1]['Content-Type'].should == 'text/plain'
    response[2].should == ["method not allowed"]
  end

end
