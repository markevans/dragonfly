module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin registers an app with generators, analysers and processors.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin

      def call(app)
        app.analyser.register(ImageMagick::Analyser, command_line)

        # Generators
        app.add_generator :plain, ImageMagick::Generator::Plain.new(command_line)
        app.add_generator :plasma, ImageMagick::Generator::Plasma.new(command_line)
        app.add_generator :text, ImageMagick::Generator::Text.new(command_line)

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
