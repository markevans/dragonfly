module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin registers an app with generators, analysers and processors.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin

      def call(app)
        # Analysers
        app.add_analyser :identify, ImageMagick::Analysers::Identify.new(command_line)
        app.add_analyser :identify_basic, ImageMagick::Analysers::IdentifyBasic.new(command_line)
        app.define :width do
          identify_basic['width']
        end
        app.define :height do
          identify_basic['height']
        end
        app.define :format do
          identify_basic['format']
        end

        # Generators
        app.add_generator :plain, ImageMagick::Generators::Plain.new(command_line)
        app.add_generator :plasma, ImageMagick::Generators::Plasma.new(command_line)
        app.add_generator :text, ImageMagick::Generators::Text.new(command_line)

        # Processors
        app.add_processor :convert, Processors::Convert.new(command_line)
        app.add_processor :thumb, Processors::Thumb.new(command_line)
        app.define :encode do |format, args=""|
          convert(args, format)
        end
      end

      def command_line
        @command_line ||= CommandLine.new
      end

      def convert_command(command)
        command_line.convert_command = command
      end

      def identify_command(command)
        command_line.identify_command = command
      end

    end
  end
end
