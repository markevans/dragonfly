module Dragonfly
  module ImageMagick
    class Processor

      include ProcessingMethods

      def initialize(command_line=nil)
        @command_line = command_line || CommandLine.new
      end

      class Convert
        include ProcessingMethods
        def initialize(command_line)
          @command_line = command_line
        end
        
        def call(temp_object, args='', format=nil)
          convert(temp_object, args, format)
        end

        def update_url(attrs, args='', format=nil)
          attrs[:format] = format if format
        end
      end

      class Encode
        include ProcessingMethods
        def initialize(command_line)
          @command_line = command_line
        end
        
        def call(temp_object, format, args=nil)
          encode(temp_object, format, args)
        end

        def update_url(attrs, format, *)
          attrs[:format] = format
        end
      end

    end
  end
end
