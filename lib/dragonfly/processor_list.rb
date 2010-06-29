module Dragonfly
  class ProcessorList
    include Delegator
    
    def initialize(app)
      @app = app
    end

    def process(temp_object, method, *args)
      delegate(method, temp_object, *args)
    end

  end
end
