module Dragonfly
  module Encoding
    
    class Base
      
      def encode(temp_object, format, options={})
        raise NotImplementedError
      end
      
    end
    
  end
end