module Dragonfly
  class RoutedEndpoint
    
    include Endpoint

    class NoRoutingParams < RuntimeError; end

    def initialize(app, &block)
      @app = app
      @block = block
    end

    def call(env)
      job = @block.call(@app, routing_params(env))
      response_for_job(job)
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

  end
end
