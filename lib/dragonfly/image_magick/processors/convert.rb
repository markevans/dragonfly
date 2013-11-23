module Dragonfly
  module ImageMagick
    module Processors
      class Convert

        def call(content, args='', opts={})
          convert_command = content.env[:convert_command] || 'convert'
          format = opts['format']

          frame_string = "[#{opts['frame']}]" if opts['frame']
          content.shell_update :ext => format do |old_path, new_path|
            "#{convert_command} #{old_path}#{frame_string} #{args} #{new_path}"
          end

          if format
            content.meta['format'] = format.to_s
            content.ext = format
          end
        end

        def update_url(attrs, args='', opts={})
          format = opts['format']
          attrs.ext = format if format
        end

      end
    end
  end
end
