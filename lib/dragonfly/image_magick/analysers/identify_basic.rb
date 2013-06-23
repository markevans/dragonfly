module Dragonfly
  module ImageMagick
    module Analysers
      class IdentifyBasic

        def call(content)
          format, width, height = content.analyse(:identify, "-ping -format '%m %w %h'").split
          {
            'format' => format.downcase,
            'width' => width.to_i,
            'height' => height.to_i
          }
        end

      end
    end
  end
end
