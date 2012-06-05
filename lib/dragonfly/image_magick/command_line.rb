module Dragonfly
  module ImageMagick
    class CommandLine

      def initialize
        @shell = Shell.new
      end

      attr_reader :shell

      def convert_command
        @convert_command ||= 'convert'
      end
      attr_writer :convert_command

      def identify_command
        @identify_command ||= 'identify'
      end
      attr_writer :identify_command

      def convert(temp_object=nil, args='', format=nil, tempfile=nil)
        tempfile ||= Dragonfly::Utils.new_tempfile(format)
        shell.run convert_command, %(#{shell.quote(temp_object.path) if temp_object} #{args} #{shell.quote(tempfile.path)})
        tempfile
      end

      def identify(temp_object)
        # example of details string:
        # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
        format, width, height, depth = raw_identify(temp_object).scan(/([A-Z0-9]+) (\d+)x(\d+) .+ (\d+)-bit/)[0]
        {
          :format => format.downcase.to_sym,
          :width => width.to_i,
          :height => height.to_i,
          :depth => depth.to_i
        }
      end

      def raw_identify(temp_object, args='')
        shell.run identify_command, "#{args} #{shell.quote(temp_object.path)}"
      end

    end
  end
end
