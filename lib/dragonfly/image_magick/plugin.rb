module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin registers an app with generators, analysers and processors.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin

      def call(app)
        app.analyser.register(ImageMagick::Analyser, command_line)

        # Generators
        app.generators.add :plain, ImageMagick::Generator::Plain.new(command_line)
        app.generators.add :plasma, ImageMagick::Generator::Plasma.new(command_line)
        app.generators.add :text, ImageMagick::Generator::Text.new(command_line)

        # Processors
        app.processors.add :convert, Processors::Convert.new(command_line)
        app.processors.add :thumb, Processors::Thumb.new(command_line)

        app.job :convert do |format, args|
          process :convert, format, args
        end
        app.job :encode do |format, args|
          process :convert, args, format
        end
        app.job :gif do
          process :encode, :gif
        end
        app.job :jpg do
          process :encode, :jpg
        end
        app.job :png do
          process :encode, :png
        end
        app.job :auto_orient do
          process :convert, '-auto-orient'
        end
        app.job :flip do
          process :convert, '-flip'
        end
        app.job :flop do
          process :convert, '-flop'
        end

        greyscale = proc do
          process :convert, '-colorspace Gray'
        end
        app.job :greyscale, &greyscale
        app.job :grayscale, &greyscale

        app.job :rotate do |amount, opts={}|
          process :convert, "-rotate #{amount}#{opts[:qualifier]}"
        end
        app.job :strip do
          process :convert, '-strip'
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
