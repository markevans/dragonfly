module Dragonfly
  class Middleware

    def initialize(app, dragonfly_app_name, deprecated_arg=nil)
      raise ArgumentError, "mounting Dragonfly::Middleware with a mount point is deprecated - just use Dragonfly::Middleware, #{dragonfly_app_name.inspect}" if deprecated_arg
      @app = app
      @dragonfly_app_name = dragonfly_app_name
    end

    def call(env)
      response = Dragonfly[@dragonfly_app_name].call(env)
      if response[1]['X-Cascade'] == 'pass'
        @app.call(env)
      else
        response
      end
    end

  end
end
