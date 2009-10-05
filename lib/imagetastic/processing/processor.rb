module Imagetastic
  module Processing
    class Processor

      include Configurable

      def register(mod)
        self.extend(mod)
      end
      configuration_method :register

    end
  end
end
