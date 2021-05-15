require "dragonfly/image_magick/commands"

module Dragonfly
  module ImageMagick
    module Generators
      class Plasma
        def call(content, width, height, opts = {})
          format = extract_format(opts)
          Commands.generate(content, "-size #{width}x#{height} plasma:fractal", format)
          content.add_meta("format" => format, "name" => "plasma.#{format}")
        end

        def update_url(url_attributes, width, height, opts = {})
          url_attributes.name = "plasma.#{extract_format(opts)}"
        end

        private

        def extract_format(opts)
          opts["format"] || "png"
        end
      end
    end
  end
end
