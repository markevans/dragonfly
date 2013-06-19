module Dragonfly
  module ImageMagick
    module Generators
      class Convert

        def initialize(command_line=nil)
          @command_line = command_line || CommandLine.new
        end

        attr_reader :command_line

        def call(content, args, format)
          format = format.to_s
          content.shell_generate :ext => format do |path|
            "#{command_line.convert_command} #{args} #{path}"
          end
          content.add_meta('format' => format)
        end

      end
    end
  end
end

