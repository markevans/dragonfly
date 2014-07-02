require 'spec_helper'

def response_for(array)
  Rack::MockResponse.new(*array)
end

describe Dragonfly::RoutedEndpoint do

  def env_for(url, opts={})
    Rack::MockRequest.env_for(url, opts)
  end

  let (:app) { test_app }
  let (:uid) { app.store('wassup') }

  describe "endpoint returning a job" do
    let (:endpoint) {
      Dragonfly::RoutedEndpoint.new(app) {|params, app|
        app.fetch(params[:uid])
      }
    }

    it "should raise an error when there are no routing parameters" do
      lambda{
        endpoint.call(env_for('/blah'))
      }.should raise_error(Dragonfly::RoutedEndpoint::NoRoutingParams)
    end

    {
      'Rails' => 'action_dispatch.request.path_parameters',
      'HTTP Router' => 'router.params',
      'Rack-Mount' => 'rack.routing_args',
      'Dragonfly' => 'dragonfly.params'
    }.each do |name, key|

      it "should work with #{name} routing args" do
        response = response_for endpoint.call(env_for('/blah', key => {:uid => uid}))
        response.body.should == 'wassup'
      end

    end

    it "should merge with query parameters" do
      env = Rack::MockRequest.env_for("/big/buns?uid=#{uid}", 'dragonfly.params' => {:something => 'else'})
      response = response_for endpoint.call(env)
      response.body.should == 'wassup'
    end

     it "should have nice inspect output" do
       endpoint.inspect.should =~ /<Dragonfly::RoutedEndpoint for app :default >/
     end
  end

  describe "env argument" do
    let (:endpoint) {
      Dragonfly::RoutedEndpoint.new(app) {|params, app, env|
        app.fetch(env['THE_UID'])
      }
    }

    it "adds the env to the arguments" do
      response = response_for endpoint.call(env_for('/blah', {"THE_UID" => uid, 'dragonfly.params' => {}}))
      response.body.should == 'wassup'
    end
  end

  describe "endpoint returning other things" do
    let (:model_class) {
      Class.new do
        extend Dragonfly::Model
        dragonfly_accessor :image
        attr_accessor :image_uid
      end
    }
    let (:model) {
      model_class.new
    }
    let (:endpoint) {
      Dragonfly::RoutedEndpoint.new(app) {|params, app|
        model.image
      }
    }

    it "acts like the job one" do
      model.image = "wassup"
      response = response_for endpoint.call(env_for('/blah', 'dragonfly.params' => {}))
      response.body.should == 'wassup'
    end

    it "returns 404 if nil is returned from the endpoint" do
      endpoint = Dragonfly::RoutedEndpoint.new(app) { nil }
      response = response_for endpoint.call(env_for('/blah', 'dragonfly.params' => {}))
      response.status.should == 404
    end

    it "returns 500 if something else is returned from the endpoint" do
      endpoint = Dragonfly::RoutedEndpoint.new(app) { "ASDF" }
      response = response_for endpoint.call(env_for('/blah', 'dragonfly.params' => {}))
      response.status.should == 500
    end
  end

end
