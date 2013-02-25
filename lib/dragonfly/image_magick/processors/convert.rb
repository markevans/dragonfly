module Dragonfly
  module ImageMagick
    module Processors
      class Convert < Base

        def call(temp_object, args='', format=nil)
          result = command_line.convert(temp_object.path, args, format)
          meta = format ? {:format => format.to_sym} : {}
          [result, meta]
        end

        def update_url(attrs, args='', format=nil)
          attrs.ext = format if format
        end

      end
    end
  end
end
