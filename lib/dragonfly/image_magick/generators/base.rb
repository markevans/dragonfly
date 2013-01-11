module Dragonfly
  module ImageMagick
    module Generators
      class Base

        def initialize(command_line=nil)
          @command_line = command_line || CommandLine.new
        end

        attr_reader :command_line

        def convert(args, format, tempfile=nil)
          command_line.convert(nil, args, format, tempfile)
        end

      end
    end
  end
end
