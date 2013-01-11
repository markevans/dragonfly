module Dragonfly
  module ImageMagick
    module Generators
      class Plain < Base

        def call(width, height, colour, opts={})
          format = opts[:format] || 'png'
          [
            convert("-size #{width}x#{height} xc:#{colour}", format),
            {:format => format.to_sym, :name => "plain.#{format}"}
          ]
        end

      end
    end
  end
end

