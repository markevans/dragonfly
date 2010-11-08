require 'tempfile'

module Dragonfly
  module ImageMagickUtils

    # Exceptions
    class ShellCommandFailed < RuntimeError; end

    class << self
      include Configurable
      configurable_attr :convert_command, "convert"
      configurable_attr :identify_command, "identify"
      configurable_attr :log_commands, false
    end
    
    include Loggable
    
    private

    def convert(temp_object, args)
      tempfile = new_tempfile
      run "#{convert_command} #{args} #{temp_object.path} #{tempfile.path}"
      tempfile
    end

    def identify(temp_object)
      # example of details string:
      # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
      details = run "#{identify_command} #{temp_object.path}"
      filename, format, geometry, geometry_2, depth, image_class, size = details.split(' ')
      width, height = geometry.split('x')
      {
        :filename => filename,
        :format => format.downcase,
        :width => width,
        :height => height,
        :depth => depth,
        :image_class => image_class,
        :size => size
      }
    end
    
    def new_tempfile(ext=nil)
      tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
      tempfile.binmode
      tempfile.close
      tempfile
    end
    
    def convert_command
      ImageMagickUtils.convert_command
    end

    def identify_command
      ImageMagickUtils.identify_command
    end

    def run(command)
      log.debug("Running command: #{command}") if ImageMagickUtils.log_commands
      result = `#{command}`
      if !$?.success?
        raise ShellCommandFailed, "Command failed (#{command}) with exit status #{$?.exitstatus}"
      end
      result
    end

  end
end
