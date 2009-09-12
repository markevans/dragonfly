module Imagetastic
  module Processing
    class Processor

      def process(temp_object, method, options)
        send(method, temp_object, options)
      end

    end
  end
end
