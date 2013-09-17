require 'dragonfly'

module Dragonfly
  class Middleware

    def initialize(app, dragonfly_app_name=nil)
      @app = app
      @dragonfly_app_name = dragonfly_app_name
    end

    def call(env)
      response = Dragonfly.app(@dragonfly_app_name).call(env)
      if response[1]['X-Cascade'] == 'pass'
        @app.call(env)
      else
        response
      end
    end

  end
end

