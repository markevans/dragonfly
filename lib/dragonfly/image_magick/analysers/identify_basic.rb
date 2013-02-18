module Dragonfly
  module ImageMagick
    module Analysers
      class IdentifyBasic < Base

        def call(temp_object)
          format, width, height = command_line.identify(temp_object, "-ping -format '%m %w %h'").split
          {
            'format' => format.downcase.to_sym,
            'width' => width.to_i,
            'height' => height.to_i
          }
        end

      end
    end
  end
end
