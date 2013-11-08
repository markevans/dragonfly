module Dragonfly
  module ImageMagick
    module Generators
      class Plain

        def call(content, width, height, opts={})
          format = extract_format(opts)
          colour = opts['colour'] || opts['color'] || 'white'
          content.generate!(:convert, "-size #{width}x#{height} xc:#{colour}", format)
          content.add_meta('format' => format, 'name' => "plain.#{format}")
        end

        def update_url(url_attributes, width, height, opts={})
          url_attributes.name = "plain.#{extract_format(opts)}"
        end

        private

        def extract_format(opts)
          opts['format'] || 'png'
        end

      end
    end
  end
end
