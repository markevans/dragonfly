require File.dirname(__FILE__) + '/../spec_helper'
require 'rack'

def dummy_rack_app
  lambda{|env| [200, {"Content-Type" => "text/html"}, ["#{env['PATH_INFO']}, #{env['QUERY_STRING']}"]] }
end

describe Dragonfly::Middleware do

  def make_request(app, url)
    Rack::MockRequest.new(app).get(url)
  end

  before(:each) do
    @stack = Rack::Builder.new do
      use Dragonfly::Middleware, :images
      run dummy_rack_app
    end
  end

  it "should continue the calling chain if the app returns a 404 for that url" do
    Dragonfly::App[:images].should_receive(:call).and_return(
      [404, {"Content-Type" => 'text/plain'}, ['Not found']]
    )
    response = make_request(@stack, 'hello.png?howare=you')
    response.status.should == 200
    response.body.should == 'hello.png, howare=you'
  end

  it "should return as per the dragonfly app if the app returns a 200" do
    Dragonfly::App[:images].should_receive(:call).and_return(
      [200, {"Content-Type" => 'text/plain'}, ['ABCD']]
    )
    response = make_request(@stack, 'hello.png?howare=you')
    response.status.should == 200
    response.body.should == 'ABCD'
  end

  it "should return as per the dragonfly app if the app returns a 400" do
    Dragonfly::App[:images].should_receive(:call).and_return(
      [400, {"Content-Type" => 'text/plain'}, ['ABCD']]
    )
    response = make_request(@stack, 'hello.png?howare=you')
    response.status.should == 400
    response.body.should == 'ABCD'
  end
  
end
