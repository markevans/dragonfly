require "dragonfly/image_magick/commands"

module Dragonfly
  module ImageMagick
    module Processors
      class Encode
        def update_url(attrs, format, args = "")
          attrs.ext = format.to_s
        end

        def call(content, format, args = "")
          Commands.convert(content, args, "format" => format)
        end
      end
    end
  end
end
