require File.dirname(__FILE__) + '/../spec_helper'

## General tests for Endpoint module go here as it's a pretty simple wrapper around that

describe Dragonfly::JobEndpoint do

  def make_request(job)
    endpoint = Dragonfly::JobEndpoint.new(job)
    Rack::MockRequest.new(endpoint).get('')
  end

  describe "errors" do

    before(:each) do
      @app = mock_app
      @job = Dragonfly::Job.new(@app).fetch('egg')
    end

    it "should return 404 if the datastore raises data not found" do
      @job.should_receive(:apply).and_raise(Dragonfly::DataStorage::DataNotFound)
      response = make_request(@job)
      response.status.should == 404
    end

    it "should raise an error if the job is empty" do
      job = Dragonfly::Job.new(@app)
      lambda{
        make_request(job)
      }.should raise_error(Dragonfly::Endpoint::EmptyJob)
    end

  end

end
