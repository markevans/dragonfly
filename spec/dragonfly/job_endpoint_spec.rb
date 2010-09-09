require File.dirname(__FILE__) + '/../spec_helper'

## General tests for Endpoint module go here as it's a pretty simple wrapper around that

describe Dragonfly::JobEndpoint do

  def make_request(job, opts={})
    endpoint = Dragonfly::JobEndpoint.new(job)
    Rack::MockRequest.new(endpoint).get('', opts)
  end

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
    response['Content-Disposition'].should == 'inline; filename="gung.txt"'
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

  describe "Content Disposition" do
    before(:each) do
      @app.encoder.add{|temp_object, format| temp_object }
    end
    it "should return the original name" do
      response = make_request(@job)
      response['Content-Disposition'].should == 'inline; filename="gung.txt"'
    end
    it "should return a filename with a different extension if it's been encoded" do
      response = make_request(@job.encode(:doogs))
      response['Content-Disposition'].should == 'inline; filename="gung.doogs"'
    end
    it "should not have the filename if name doesn't exist" do
      response = make_request(@app.new_job("ADFSDF"))
      response['Content-Disposition'].should == 'inline'
    end
    it "should cope with filenames with no ext" do
      response = make_request(@app.new_job("ASDF", :name => 'asdf'))
      response['Content-Disposition'].should == 'inline; filename="asdf"'
    end
    it "should uri encode funny characters" do
      response = make_request(@app.new_job("ASDF", :name => '£@$£ `'))
      response['Content-Disposition'].should == 'inline; filename="%C2%A3@$%C2%A3%20%60"'
    end
  end

end
