module Dragonfly
  class EncoderList
    include Delegator
    
    def initialize(app)
      @app = app
    end
  end
end
