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

      def identify(temp_object, args="")
        shell.run(identify_command, "#{args} #{shell.quote(temp_object.path)}").strip
      end

    end
  end
end
