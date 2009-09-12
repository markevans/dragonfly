module Imagetastic
  module Processing
    class Base

      def process(temp_object, method, options)
        send(method, temp_object, options)
      end

    end
  end
end
