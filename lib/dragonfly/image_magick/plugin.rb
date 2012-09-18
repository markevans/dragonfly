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

      class Convert
        include ProcessingMethods
        def initialize(command_line)
          @command_line = command_line
        end
        
        def call(temp_object, args='', format=nil)
          convert(temp_object, args, format)
        end

        def update_url(attrs, args='', format=nil)
          attrs[:format] = format if format
        end
      end

      def call(app)
        app.analyser.register(ImageMagick::Analyser, command_line)
        app.encoder.register(ImageMagick::Encoder, command_line)
        app.generator.register(ImageMagick::Generator, command_line)

        app.processors.delegate_to(processor, [
          :resize,
          :auto_orient,
          :crop,
          :flip,
          :flop,
          :greyscale,
          :grayscale,
          :resize_and_crop,
          :rotate,
          :strip,
          :thumb
        ])
        app.processors.add :convert, Convert.new(command_line)

        app.configure do
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
          job :convert do |args, format|
            process :convert, args, format
          end
        end
      end

      def processor
        @processor ||= Processor.new(command_line)
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
