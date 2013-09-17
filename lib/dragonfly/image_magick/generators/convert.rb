module Dragonfly
  module ImageMagick
    module Generators
      class Convert

        def call(content, args, format)
          format = format.to_s
          convert_command = content.env[:convert_command] || 'convert'
          content.shell_generate :ext => format do |path|
            "#{convert_command} #{args} #{path}"
          end
          content.add_meta('format' => format)
        end

      end
    end
  end
end

