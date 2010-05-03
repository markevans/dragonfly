module Dragonfly
  class ProcessorList
    include Delegator
    
    def initialize(app)
      @app = app
    end
  end
end
