module Dragonfly
  class AnalyserList
    include Delegator
    
    def initialize(app)
      @app = app
    end
  end
end
