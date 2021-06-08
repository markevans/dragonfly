require "dragonfly/image_magick/commands"

module Dragonfly
  module ImageMagick
    module Processors
      class Encode
        include ParamValidators

        WHITELISTED_ARGS = %w(quality flatten)

        IS_IN_WHITELISTED_ARGS = ->(args_string) {
          args_string.scan(/-\w+/).all? { |arg|
            WHITELISTED_ARGS.include?(arg.sub("-", ""))
          }
        }

        def update_url(attrs, format, args = "")
          attrs.ext = format.to_s
        end

        def call(content, format, args = "")
          validate!(format, &is_word)
          validate!(args, &IS_IN_WHITELISTED_ARGS)
          Commands.convert(content, args, "format" => format)
        end
      end
    end
  end
end
