module Dragonfly
  module ImageMagick
    module Analysers
      class Identify

        def initialize(command_line=nil)
          @command_line = command_line || CommandLine.new
        end

        attr_reader :command_line


        def call(content, args="")
          content.shell_eval do |path|
            "#{command_line.identify_command} #{args} #{path}"
          end
        end

      end
    end
  end
end
