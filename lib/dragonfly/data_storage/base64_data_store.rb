require "base64"

module Dragonfly
  module DataStorage

    class Base64DataStore < Base

      def store(temp_object)
        Base64.encode64(temp_object.data)
      end

      def retrieve(uid)
        Base64.decode64(uid)
      end
      
      def destroy(uid)
        # Nothing to destroy!
      end
      
    end
    
  end
end
