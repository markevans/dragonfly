module Dragonfly
  class Middleware

    def initialize(app, dragonfly_app_name, path_prefix)
      @app = app
      @endpoint = Rack::Builder.new {
        map path_prefix do
          run Dragonfly[dragonfly_app_name]
        end
      }.to_app
    end

    def call(env)
      response = @endpoint.call(env)
      if route_not_found?(response)
        @app.call(env)
      else
        response
      end
    end

    private

    def route_not_found?(response)
      response[1]['X-Cascade'] == 'pass' ||
        (rack_version_doesnt_support_x_cascade? && response[0] == 404)
    end

    def rack_version_doesnt_support_x_cascade?
      Rack.version < '1.1'
    end

  end
end
