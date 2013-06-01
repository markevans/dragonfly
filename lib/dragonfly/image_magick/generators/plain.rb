module Dragonfly
  module ImageMagick
    module Generators
      class Plain < Base

        def call(content, width, height, opts={})
          format = opts['format'] || 'png'
          colour = opts['colour'] || opts['color'] || 'white'
          content.shell_generate :ext => format do |path|
            "#{command_line.convert_command} -size #{width}x#{height} xc:#{colour} #{path}"
          end
          content.add_meta('format' => format, 'name' => "plain.#{format}")
        end

      end
    end
  end
end

