module Dragonfly
  class Analyser
    include Delegator
    
    def initialize(app)
      @app = app
    end
    
    def analyse(temp_object, method, *args)
      delegate(method, temp_object, *args)
    end
    
  end
end
