module Dragonfly
  module ImageMagick
    module Generators
      class Plain

        def call(content, width, height, opts={})
          format = opts['format'] || 'png'
          colour = opts['colour'] || opts['color'] || 'white'
          content.generate!(:convert, "-size #{width}x#{height} xc:#{colour}", format)
          content.add_meta('format' => format, 'name' => "plain.#{format}")
        end

      end
    end
  end
end

