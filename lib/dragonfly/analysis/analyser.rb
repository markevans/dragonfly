module Dragonfly
  module Analysis
    class Analyser

      include Configurable
      include Delegator
      configuration_method :register

    end
  end
end