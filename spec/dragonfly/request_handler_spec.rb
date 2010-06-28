# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::RequestHandler do
  
  include Dragonfly::Serializer
  
  before(:each) do
    @request_handler = Dragonfly::RequestHandler.new
  end

  def env_for(path)
    Rack::MockRequest.env_for("http://doogie.com#{path}")
  end
  
  describe "initializing with an env" do
    it "should raise an error if the request is not initialized" do
      lambda{
        @request_handler.request
      }.should raise_error(Dragonfly::RequestHandler::NotInitialized)
    end
  
    it "should not raise an error if the request is initialized" do
      @request_handler.init!(env_for('/'))
      lambda{
        @request_handler.request
      }.should_not raise_error
    end
  end
  
  describe "Denial-of-service protection" do
    it "should have DOS protection turned off by default" do
      @request_handler.protect_from_dos_attacks.should be_false
    end
    
    describe "generate_sha" do
      before(:each) do
        @request_handler.init! env_for('/hellothere')
        @sha = @request_handler.generate_sha
      end
      it "should generate a sha of the correct length" do
        @sha.length.should > 0
        @sha.length.should == @request_handler.sha_length
      end
      it "should depend on the path" do
        @request_handler.should_receive(:path).and_return('/newpath')
        @request_handler.generate_sha.should_not == @sha
      end
      it "should depend on the secret" do
        @request_handler.secret = 'some new secret'
        @request_handler.generate_sha.should_not == @sha
      end
      it "should not depend on the host" do
        @request_handler.init! Rack::MockRequest.env_for("http://otherhost.com/hellothere")
        @request_handler.generate_sha.should == @sha
      end
      it "should not depend on query params" do
        @request_handler.init! env_for("/hellothere?somequery=params")
        @request_handler.generate_sha.should == @sha
      end
    end
  end

end