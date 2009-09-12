module Imagetastic
  module DataStorage
    class Base

      def store(temp_object)
        raise NotImplementedError
      end

      def retrieve(id)
        raise NotImplementedError
      end

    end
  end
end
