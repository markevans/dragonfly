module Dragonfly

  class Middleware
    
    def initialize(app, dragonfly_app_name)
      @app = app
      @dragonfly_app_name = dragonfly_app_name
    end
    
    def call(env)
      response = endpoint.call(env)
      if response[0] == 404
        @app.call(env)
      else
        response
      end
    end
    
    private
    
    def endpoint
      App[@dragonfly_app_name]
    end
    
  end

end