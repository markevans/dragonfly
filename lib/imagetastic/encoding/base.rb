module Imagetastic
  module Encoding
    
    class Base
      
      def encode(temp_object, mime_type, encoding={})
        raise NotImplementedError
      end
      
    end
    
  end
end