module Dragonfly
  module BelongsToApp
    
    # Exceptions
    class NotConfigured < RuntimeError; end
    
    attr_writer :app
    
    def app
      @app || raise(NotConfigured, "#{self.inspect} has no app set")
    end
    
    def app_set?
      !!@app
    end
    
    def log
      app.log
    end
    
  end
end
