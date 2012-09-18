module Dragonfly
  module ImageMagick
    class Processor

      include ProcessingMethods

      def initialize(command_line=nil)
        @command_line = command_line || CommandLine.new
      end

    end
  end
end
