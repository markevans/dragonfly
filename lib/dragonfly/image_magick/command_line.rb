module Dragonfly
  module ImageMagick
    class CommandLine
      def initialize
        @convert_command = 'convert'
        @identify_command = 'identify'
      end

      attr_accessor :convert_command
      attr_accessor :identify_command
    end
  end
end
