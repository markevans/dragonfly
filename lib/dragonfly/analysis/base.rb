module Dragonfly
  module Analysis
    class Base

      include Delegatable

      def mime_type(*args)
        throw :unable_to_handle
      end

    end
  end
end