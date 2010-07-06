module Dragonfly
  class Processor
    include Delegator
    
    def initialize(app)
      @app = app
    end

    def process(temp_object, method, *args)
      delegate(method, temp_object, *args)
    end

  end
end
