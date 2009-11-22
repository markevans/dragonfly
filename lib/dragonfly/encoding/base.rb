module Dragonfly
  module Encoding
    
    class Base
      
      def encode(*args)
        throw :unable_to_handle
      end
      
    end
    
  end
end