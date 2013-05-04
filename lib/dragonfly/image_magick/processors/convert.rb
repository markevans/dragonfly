module Dragonfly
  module ImageMagick
    module Processors
      class Convert

        def initialize(command_line=nil)
          @command_line = command_line
        end

        def command_line
          @command_line ||= CommandLine.new
        end

        def call(content, args='', format=nil)
          content.shell_update :ext => format do |old_path, new_path|
            "#{command_line.convert_command} #{old_path} #{args} #{new_path}"
          end
          if format
            content.meta['format'] = format.to_s
            content.ext = format
          end
        end

        def update_url(attrs, args='', format=nil)
          attrs.ext = format if format
        end

      end
    end
  end
end
