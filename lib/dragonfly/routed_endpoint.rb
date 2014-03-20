require 'rack'
require 'dragonfly/utils'
require 'dragonfly/response'

module Dragonfly
  class RoutedEndpoint

    class NoRoutingParams < RuntimeError; end

    def initialize(app, &block)
      @app = app
      @block = block
    end

    def call(env)
      params = Utils.symbolize_keys Rack::Request.new(env).params
      value = @block.call(params.merge(routing_params(env)), @app, env)
      case value
      when nil then plain_response(404, "Not Found")
      when Job, Model::Attachment
        job = value.is_a?(Model::Attachment) ? value.job : value
        Response.new(job, env).to_response
      else
        Dragonfly.warn("can't handle return value from routed endpoint: #{value.inspect}")
        plain_response(500, "Server Error")
      end
    rescue Job::NoSHAGiven => e
      plain_response(400, "You need to give a SHA parameter")
    rescue Job::IncorrectSHA => e
      plain_response(400, "The SHA parameter you gave is incorrect")
    end

    def inspect
      "<#{self.class.name} for app #{@app.name.inspect} >"
    end

    private

    def routing_params(env)
      env['rack.routing_args'] ||
        env['action_dispatch.request.path_parameters'] ||
        env['router.params'] ||
        env['dragonfly.params'] ||
        raise(NoRoutingParams, "couldn't find any routing parameters in env #{env.inspect}")
    end

    def plain_response(status, message)
      [status, {"Content-Type" => "text/plain"}, [message]]
    end
  end
end
