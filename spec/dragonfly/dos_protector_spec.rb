require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::DosProtector do

  def make_request(app, url)
    Rack::MockRequest.new(app).get(url)
  end

  describe "without extra configuration" do
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
      response = make_request(@app, 'http://example.com/hello/there?s=22d94173b7eb3671')
      response.status.should == 200
      response.body.should == "Hi everyone!"
    end
  end

  describe "with the sha length configured" do
    before(:each) do
      @app = Rack::Builder.new do
        use Dragonfly::DosProtector, 'mysecret', :sha_length => 8
        run lambda{|env| [200, {"Content-Type" => "text/plain"}, ["Hi everyone!"]] }
      end
    end

    it "should not accept a sha of the wrong length" do
      response = make_request(@app, 'http://example.com/hello/there?s=22d94173b7eb3671')
      response.status.should == 400
    end

    it "should accept a sha of the correct length" do
      response = make_request(@app, 'http://example.com/hello/there?s=22d94173')
      response.status.should == 200
    end
  end

  describe "required_params_for" do
    it "should give the required sha params for it to pass" do
      Dragonfly::DosProtector.required_params_for('/hello/there', 'mysecret').should == {'s' => '22d94173b7eb3671'}
    end
    it "should take into account the sha_length" do
      Dragonfly::DosProtector.required_params_for('/hello/there', 'mysecret', :sha_length => 8).should == {'s' => '22d94173'}
    end
  end


  describe "with constraints" do
    before(:each) do
      @app = Rack::Builder.new do
        use Dragonfly::DosProtector, 'mysecret', :path_info => %r{^/doogie}
        run lambda{|env| [200, {"Content-Type" => "text/plain"}, ["Hi everyone!"]] }
      end
    end

    it "should work on urls that match the constraint" do
      response = make_request(@app, 'http://example.com/doogie/bugs')
      response.status.should == 400
    end

    it "should do nothing on urls that don't match the constraint" do
      response = make_request(@app, 'http://example.com/dofogie/bugs')
      response.status.should == 200
    end
  end

end
