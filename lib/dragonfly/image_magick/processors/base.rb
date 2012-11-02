module Dragonfly
  module ImageMagick
    module Processors
      class Base

        def initialize(command_line=nil)
          @command_line = command_line
        end

        def command_line
          @command_line ||= CommandLine.new
        end

      end
    end
  end
end
