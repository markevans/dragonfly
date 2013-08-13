module Dragonfly
  module ImageMagick
    module Analysers
      class Identify

        def initialize(command_line=nil)
          @command_line = command_line || CommandLine.new
        end

        attr_reader :command_line


        def call(content)
          details = content.shell_eval do |path|
            "#{command_line.identify_command} -ping -format '%m %w %h' #{path}"
          end
          format, width, height = details.split
          {
            'format' => format.downcase,
            'width' => width.to_i,
            'height' => height.to_i
          }
        end

      end
    end
  end
end

