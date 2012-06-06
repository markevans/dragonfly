module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin does the following:
    # - registers an imagemagick analyser
    # - registers an imagemagick processor
    # - registers an imagemagick encoder
    # - registers an imagemagick generator
    # - adds thumb shortcuts like '280x140!', etc.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin
      
      def call(app)
        command_line = self.command_line
        app.configure do
          analyser.register(ImageMagick::Analyser, command_line)
          processor.register(ImageMagick::Processor, command_line)
          encoder.register(ImageMagick::Encoder, command_line)
          generator.register(ImageMagick::Generator, command_line)

          job :thumb do |geometry, format|
            process :thumb, geometry
            encode format if format
          end
          job :gif do
            encode :gif
          end
          job :jpg do
            encode :jpg
          end
          job :png do
            encode :png
          end
          job :strip do
            process :strip
          end
          job :convert do |args, format|
            process :convert, args, format
          end
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
