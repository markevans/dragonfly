require "dragonfly/image_magick/commands"
require "dragonfly/param_validators"

module Dragonfly
  module ImageMagick
    module Generators
      class Plain
        include ParamValidators

        def call(content, width, height, opts = {})
          validate_all!([width, height], &is_number)
          validate!(opts["format"], &is_word)
          validate_all_keys!(opts, %w(colour color), &is_colour)
          format = extract_format(opts)

          colour = opts["colour"] || opts["color"] || "white"
          Commands.generate(content, "-size #{width}x#{height} xc:#{colour}", format)
          content.add_meta("format" => format, "name" => "plain.#{format}")
        end

        def update_url(url_attributes, width, height, opts = {})
          url_attributes.name = "plain.#{extract_format(opts)}"
        end

        private

        def extract_format(opts)
          opts["format"] || "png"
        end
      end
    end
  end
end
