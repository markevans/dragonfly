module Dragonfly
  module DataStorage

    class TransparentDataStore < Base
      
      def store(temp_object)
        temp_object.data
      end

      def retrieve(uid)
        uid
      end
      
      def destroy(uid)
        # Nothing to destroy!
      end
      
    end
    
  end
end