module Dragonfly
  module Analysis
    class Analyser
      
      include Configurable

      def register(mod)
        self.extend(mod)
      end
      configuration_method :register

    end
  end
end