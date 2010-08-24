require File.dirname(__FILE__) + '/../spec_helper'

def response_for(array)
  Rack::MockResponse.new(*array)
end

describe Dragonfly::RoutedEndpoint do

  before(:each) do
    @app = test_app
    @endpoint = Dragonfly::RoutedEndpoint.new(@app) {|params, app|
      app.fetch(params[:uid])
    }
    @app.datastore.stub!(:retrieve).with('some_uid').and_return Dragonfly::TempObject.new('wassup')
  end

  it "should raise an error when there are no routing parameters" do
    lambda{
      @endpoint.call({})
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
      response = response_for @endpoint.call(key => {:uid => 'some_uid'})
      response.body.should == 'wassup'
    end
    
  end

end
