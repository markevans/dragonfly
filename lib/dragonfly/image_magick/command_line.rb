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

      def convert(path=nil, args='', format=nil, tempfile=nil)
        tempfile ||= Dragonfly::Utils.new_tempfile(format)
        shell.run convert_command, %(#{shell.quote(path) if path} #{args} #{shell.quote(tempfile.path)})
        tempfile
      end

      def identify(path, args="")
        shell.run(identify_command, "#{args} #{shell.quote(path)}").strip
      end

    end
  end
end
