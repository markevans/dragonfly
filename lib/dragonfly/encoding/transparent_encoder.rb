module Dragonfly
  module Encoding
    
    class TransparentEncoder < Base
      
      # Does nothing
      def encode(temp_object, format, encoding={})
        temp_object.file
      end
      
    end
    
  end
end
