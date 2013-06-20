module Dragonfly
  module ImageMagick
    module Generators
      class Plasma

        def call(content, width, height, opts={})
          format = opts['format'] || 'png'
          content.generate!(:convert, "-size #{width}x#{height} plasma:fractal", format)
          content.add_meta('format' => format, 'name' => "plasma.#{format}")
        end

      end
    end
  end
end
