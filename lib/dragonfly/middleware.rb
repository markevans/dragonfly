module Dragonfly

  class Middleware
    
    def initialize(app_name)
      @app_name = app_name
    end
    
    # This is the new that will be called due to being part of the rack middleware stack
    def new(*args)
      MiddlewareInstance.new(*([@app_name] + args))
    end
    
  end

  class MiddlewareInstance
    
    def initialize(dragonfly_app_name, app, path=nil)
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