module Dragonfly

  class Middleware
    
    def initialize(app, dragonfly_app_name)
      @app = app
      @dragonfly_app_name = dragonfly_app_name
    end
    
    def call(env)
      response = dragonfly_app.call(env)
      if response[0] == 404
        @app.call(env)
      else
        response
      end
    end
    
    private
    
    def dragonfly_app
      App[@dragonfly_app_name]
    end
    
  end

end