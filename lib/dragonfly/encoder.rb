module Dragonfly
  class Encoder
    include Delegator
    
    def initialize(app)
      @app = app
    end
  end
end
