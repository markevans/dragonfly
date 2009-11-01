module Dragonfly
  module Encoding
    
    class Base
      
      def encode(temp_object, mime_type, options={})
        raise NotImplementedError
      end
      
    end
    
  end
end