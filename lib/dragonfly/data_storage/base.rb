module Dragonfly
  module DataStorage
    class Base

      include BelongsToApp

      def store(temp_object)
        raise NotImplementedError
      end

      def retrieve(uid)
        raise NotImplementedError
      end
      
      def destroy(uid)
        raise NotImplementedError
      end

    end
  end
end
