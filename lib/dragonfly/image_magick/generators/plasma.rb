module Dragonfly
  module ImageMagick
    module Generators
      class Plasma < Base

        def call(width, height, format='png')
          [
            convert("-size #{width}x#{height} plasma:fractal", format),
            {:format => format.to_sym, :name => "plasma.#{format}"}
          ]
        end

      end
    end
  end
end
