module Dragonfly
  module ImageMagick
    class Analyser

      def initialize(command_line=nil)
        @command_line = command_line || CommandLine.new
      end

      attr_reader :command_line

      def width(temp_object)
        identify(temp_object)[:width]
      end

      def height(temp_object)
        identify(temp_object)[:height]
      end

      def aspect_ratio(temp_object)
        attrs = identify(temp_object)
        attrs[:width].to_f / attrs[:height]
      end

      def portrait?(temp_object)
        attrs = identify(temp_object)
        attrs[:width] <= attrs[:height]
      end
      alias portrait portrait?

      def landscape?(temp_object)
        attrs = identify(temp_object)
        attrs[:width] >= attrs[:height]
      end
      alias landscape landscape?

      def format(temp_object)
        identify(temp_object)[:format]
      end

      def image?(temp_object)
        identify(temp_object)
        true
      rescue Shell::CommandFailed
        false
      end

      private

      def identify(temp_object)
        command_line.identify(temp_object)
      end

    end
  end
end
