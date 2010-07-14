require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::JobEndpoint do

  def make_request(endpoint)
    Rack::MockRequest.new(endpoint).get('')
  end

  before(:each) do
    @app = mock_app
    @job = Dragonfly::Job.new(@app).fetch('egg')
    @endpoint = Dragonfly::JobEndpoint.new(@job)
  end

  describe "Content-Type header" do
    before(:each) do
      @job.stub!(:mime_type).and_return(nil)
      @app.stub!(:fallback_mime_type).and_return('application/octet-stream')
      @job.stub!(:analyse).with(:mime_type).and_return(nil)
    end
    it "should return the fallback mime_type if nothing from job/analysis" do
      make_request(@endpoint).headers['Content-Type'].should == 'application/octet-stream'
    end
    it "should return the analysed mime-type if returns something" do
      @job.should_receive(:analyse).with(:mime_type).and_return('your/mum')
      make_request(@endpoint).headers['Content-Type'].should == 'your/mum'
    end
    it "should return the job's mime_type not the analysed one if both exist" do
      @job.should_receive(:mime_type).and_return('numb/nut')
      @job.should_not_receive(:analyse).with(:mime_type)
      make_request(@endpoint).headers['Content-Type'].should == 'numb/nut'
    end
  end

  describe "errors" do

    it "should return 404 if the datastore raises data not found" do
      @job.should_receive(:apply).and_raise(Dragonfly::DataStorage::DataNotFound)
      response = make_request(@endpoint)
      response.status.should == 404
    end

    it "should raise an error if the job is empty" do
      endpoint = Dragonfly::JobEndpoint.new(Dragonfly::Job.new(@app))
      lambda{
        make_request(endpoint)
      }.should raise_error(Dragonfly::Endpoint::EmptyJob)
    end

  end

end
