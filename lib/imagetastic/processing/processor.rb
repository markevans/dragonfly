module Imagetastic
  module Processing
    class Processor

      def process(image, method, options)
        send(method, image, options)
      end

    end
  end
end
