module Dragonfly
  module Encoding
    
    class TransparentEncoder
      
      # Does nothing
      def encode(temp_object, format, encoding={})
        temp_object
      end
      
    end
    
  end
end
