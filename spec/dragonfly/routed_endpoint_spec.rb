require 'spec_helper'

def response_for(array)
  Rack::MockResponse.new(*array)
end

describe Dragonfly::RoutedEndpoint do

  def env_for(url, opts={})
    Rack::MockRequest.env_for(url, opts)
  end

  before(:each) do
    @app = test_app
    @endpoint = Dragonfly::RoutedEndpoint.new(@app) {|params, app|
      app.fetch(params[:uid])
    }
    @uid = @app.store('wassup')
  end

  it "should raise an error when there are no routing parameters" do
    lambda{
      @endpoint.call(env_for('/blah'))
    }.should raise_error(Dragonfly::RoutedEndpoint::NoRoutingParams)
  end

  {
    'Rails' => 'action_dispatch.request.path_parameters',
    'Usher' => 'usher.params',
    'HTTP Router' => 'router.params',
    'Rack-Mount' => 'rack.routing_args',
    'Dragonfly' => 'dragonfly.params'
  }.each do |name, key|

    it "should work with #{name} routing args" do
      response = response_for @endpoint.call(env_for('/blah', key => {:uid => @uid}))
      response.body.should == 'wassup'
    end

  end

  it "should merge with query parameters" do
    env = Rack::MockRequest.env_for("/big/buns?uid=#{@uid}", 'dragonfly.params' => {:something => 'else'})
    response = response_for @endpoint.call(env)
    response.body.should == 'wassup'
  end

   it "should have nice inspect output" do
     @endpoint.inspect.should =~ /<Dragonfly::RoutedEndpoint for app :default >/
   end

end
