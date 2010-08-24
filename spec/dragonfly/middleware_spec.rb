require File.dirname(__FILE__) + '/../spec_helper'
require 'rack'

def dummy_rack_app
  lambda{|env| [200, {"Content-Type" => "text/html"}, ["dummy_rack_app body"]] }
end

describe Dragonfly::Middleware do

  def make_request(app, url)
    Rack::MockRequest.new(app).get(url)
  end

  before(:each) do
    @stack = Rack::Builder.new do
      use Dragonfly::Middleware, :images, '/media'
      run dummy_rack_app
    end
  end

  it "should pass through for urls with incorrect prefix" do
    Dragonfly[:images].should_not_receive(:call)
    response = make_request(@stack, '/hello.png?howare=you')
    response.status.should == 200
    response.body.should == 'dummy_rack_app body'
  end

  it "should pass through if the app returns and X-Cascade: pass" do
    Dragonfly[:images].should_receive(:call).and_return(
      [404, {"Content-Type" => 'text/plain', 'X-Cascade' => 'pass'}, ['Not found']]
    )
    response = make_request(@stack, '/media/hello.png?howare=you')
    response.body.should == 'dummy_rack_app body'
  end

  it "should return a 404 if the app returns a 404 for that url but no X-Cascade: pass" do
    Dragonfly[:images].should_receive(:call).and_return(
      [404, {"Content-Type" => 'text/plain'}, ['Not found']]
    )
    response = make_request(@stack, '/media/hello.png?howare=you')
    response.status.should == 404
  end

  %w(0.1 0.9 0.10 1.0 1.0.0 1.0.1).each do |version|
    it "should pass through if the rack version is #{version} (i.e. no X-Cascade: pass) and the app returns 404" do
      Rack.should_receive(:version).and_return(version)
      Dragonfly[:images].should_receive(:call).and_return(
        [404, {"Content-Type" => 'text/plain'}, ['Not found']]
      )
      response = make_request(@stack, '/media/hello.png?howare=you')
      response.status.should == 200
      response.body.should == 'dummy_rack_app body'
    end
  end

  %w(1.1 1.1.1 2.9).each do |version|
  end

  it "should return as per the dragonfly app if the app returns a 200" do
    Dragonfly[:images].should_receive(:call).and_return(
      [200, {"Content-Type" => 'text/plain'}, ['ABCD']]
    )
    response = make_request(@stack, '/media/hello.png?howare=you')
    response.status.should == 200
    response.body.should == 'ABCD'
  end
  
end
