require 'logger'

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
      app_set? ? app.log : (@log ||= Logger.new(STDOUT))
    end
    
  end
end
