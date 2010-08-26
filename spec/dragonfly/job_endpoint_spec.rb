require File.dirname(__FILE__) + '/../spec_helper'

## General tests for Endpoint module go here as it's a pretty simple wrapper around that

describe Dragonfly::JobEndpoint do

  def make_request(job, opts={})
    endpoint = Dragonfly::JobEndpoint.new(job)
    Rack::MockRequest.new(endpoint).get('', opts)
  end

  describe "errors" do

    before(:each) do
      @app = test_app
      @app.datastore.stub!(:retrieve).with('egg').and_return(["GUNGLE", {:name => 'gung.txt'}])
      @job = Dragonfly::Job.new(@app).fetch('egg')
    end

    it "should return a correct response if successful" do
      response = make_request(@job)
      response.status.should == 200
      response['ETag'].should =~ /^"\w+"$/
      response['Cache-Control'].should == "public, max-age=31536000"
      response['Content-Type'].should == 'text/plain'
      response['Content-Length'].should == '6'
      response.body.should == 'GUNGLE'
    end

    it "should return 404 if the datastore raises data not found" do
      @job.should_receive(:apply).and_raise(Dragonfly::DataStorage::DataNotFound)
      response = make_request(@job)
      response.status.should == 404
    end

    describe "ETag" do
      it "should return an ETag" do
        response = make_request(@job)
        response.headers['ETag'].should =~ /^"\w+"$/
      end

      [
        "dingle",
        "dingle, eggheads",
        '"dingle", "eggheads"',
        '*'
      ].each do |header|
        it "should return a 304 if the correct ETag is specified in HTTP_IF_NONE_MATCH header e.g. #{header}" do
          @job.should_receive(:unique_signature).at_least(:once).and_return('dingle')
          response = make_request(@job, 'HTTP_IF_NONE_MATCH' => header)
          response.status.should == 304
          response['ETag'].should == '"dingle"'
          response['Cache-Control'].should == "public, max-age=31536000"
          response.body.should be_empty
        end
      end

      it "should not have applied any steps if the correct ETag is specified in HTTP_IF_NONE_MATCH header" do
        response = make_request(@job, 'HTTP_IF_NONE_MATCH' => @job.unique_signature)
        @job.applied_steps.should be_empty
      end
    end

  end

end
