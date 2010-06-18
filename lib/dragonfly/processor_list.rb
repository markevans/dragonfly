module Dragonfly
  class ProcessorList
    include Delegator
    
    def initialize(app)
      @app = app
    end

    def process(method, *args)
      delegate(meth, *args)
    end

  end
end
