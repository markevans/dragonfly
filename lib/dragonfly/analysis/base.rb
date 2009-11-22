module Dragonfly
  module Analysis
    class Base
      
      def mime_type(*args)
        throw :unable_to_handle
      end
      
    end
  end
end