require 'spec_helper'
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
      use Dragonfly::Middleware, :images
      run dummy_rack_app
    end
  end

  it "should pass through if the app returns X-Cascade: pass" do
    Dragonfly[:images].should_receive(:call).and_return(
      [404, {"Content-Type" => 'text/plain', 'X-Cascade' => 'pass'}, ['Not found']]
    )
    response = make_request(@stack, '/media/hello.png?howare=you')
    response.body.should == 'dummy_rack_app body'
    response.status.should == 200
  end

  it "should return a 404 if the app returns a 404" do
    Dragonfly[:images].should_receive(:call).and_return(
      [404, {"Content-Type" => 'text/plain'}, ['Not found']]
    )
    response = make_request(@stack, '/media/hello.png?howare=you')
    response.status.should == 404
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
