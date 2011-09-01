require 'tempfile'
require 'shellwords'

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
        run convert_command, %(#{quote(temp_object.path) if temp_object} #{args} #{quote(tempfile.path)})
        tempfile
      end

      def identify(temp_object)
        # example of details string:
        # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
        format, geometry, depth = raw_identify(temp_object).scan(/([A-Z]+) (.+) .+ (\d+)-bit/)[0]
        width, height = geometry.split('x')
        {
          :format => format.downcase.to_sym,
          :width => width.to_i,
          :height => height.to_i,
          :depth => depth.to_i
        }
      end
    
      def raw_identify(temp_object, args='')
        run identify_command, "#{args} #{quote(temp_object.path)}"
      end
    
      def new_tempfile(ext=nil)
        tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
        tempfile.binmode
        tempfile.close
        tempfile
      end

      def run(command, args="")
        full_command = "#{command} #{escape_args(args)}"
        log.debug("Running command: #{full_command}") if log_commands
        begin
          result = `#{full_command}`
        rescue Errno::ENOENT
          raise_shell_command_failed(full_command)
        end
        if $?.exitstatus == 1
          throw :unable_to_handle
        elsif !$?.success?
          raise_shell_command_failed(full_command)
        end
        result
      end
    
      def raise_shell_command_failed(command)
        raise ShellCommandFailed, "Command failed (#{command}) with exit status #{$?.exitstatus}"
      end
      
      def escape_args(args)
        args.shellsplit.map do |arg|
          quote arg.gsub(/\\?'/, %q('\\\\''))
        end.join(' ')
      end
      
      def quote(string)
        q = running_on_windows? ? '"' : "'"
        q + string + q
      end

      def running_on_windows?
        ENV['OS'] && ENV['OS'].downcase == 'windows_nt'
      end

    end
  end
end
