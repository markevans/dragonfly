module Dragonfly
  class RoutedEndpoint

    class NoRoutingParams < RuntimeError; end

    def initialize(app, &block)
      @app = app
      @block = block
    end

    def call(env)
      params = symbolize_keys_of Rack::Request.new(env).params
      job = @block.call(params.merge(routing_params(env)), @app)
      Response.new(job, env).to_response
    rescue Job::NoSHAGiven => e
      [400, {"Content-Type" => 'text/plain'}, ["You need to give a SHA parameter"]]
    rescue Job::IncorrectSHA => e
      [400, {"Content-Type" => 'text/plain'}, ["The SHA parameter you gave (#{e}) is incorrect"]]
    end

    def inspect
      "<#{self.class.name} for app #{@app.name.inspect} >"
    end

    private

    def routing_params(env)
      env['rack.routing_args'] ||
        env['action_dispatch.request.path_parameters'] ||
        env['router.params'] ||
        env['usher.params'] ||
        env['dragonfly.params'] ||
        raise(NoRoutingParams, "couldn't find any routing parameters in env #{env.inspect}")
    end

    def symbolize_keys_of(hash)
      hash.inject({}) do |h, (key, value)|
        h[(key.to_sym rescue key) || key] = value
        h
      end
    end

  end
end
