require 'tempfile'

module Dragonfly
  module ImageMagick
    module Utils

      # Exceptions
      class ShellCommandFailed < RuntimeError; end

      include Loggable
      include Configurable
      configurable_attr :convert_command, "convert"
      configurable_attr :identify_command, "identify"
      configurable_attr :log_commands, false
    
      private

      def convert(temp_object=nil, args='', format=nil)
        tempfile = new_tempfile(format)
        run "#{convert_command} #{quote(temp_object.path) if temp_object} #{args} #{quote(tempfile.path)}"
        tempfile
      end

      def identify(temp_object)
        # example of details string:
        # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
        details = raw_identify(temp_object)
        filename, format, geometry, geometry_2, depth, image_class, size = details.split(' ')
        width, height = geometry.split('x')
        {
          :filename => filename,
          :format => format.downcase.to_sym,
          :width => width.to_i,
          :height => height.to_i,
          :depth => depth.to_i,
          :image_class => image_class
        }
      end
    
      def raw_identify(temp_object, args='')
        run "#{identify_command} #{args} #{quote(temp_object.path)}"
      end
    
      def new_tempfile(ext=nil)
        tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
        tempfile.binmode
        tempfile.close
        tempfile
      end

      def run(command)
        log.debug("Running command: #{command}") if log_commands
        begin
          result = `#{command}`
        rescue Errno::ENOENT
          raise_shell_command_failed(command)
        end
        if $?.exitstatus == 1
          throw :unable_to_handle
        elsif !$?.success?
          raise_shell_command_failed(command)
        end
        result
      end
    
      def raise_shell_command_failed(command)
        raise ShellCommandFailed, "Command failed (#{command}) with exit status #{$?.exitstatus}"
      end

      def quote(path)
        "'#{path}'"
      end

    end
  end
end
