module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin registers an app with generators, analysers and processors.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin

      def call(app)
        # Analysers
        app.add_analyser :identify, ImageMagick::Analysers::Identify.new(command_line)
        app.add_analyser :width do |content|
          content.analyse(:identify)['width']
        end
        app.add_analyser :height do |content|
          content.analyse(:identify)['height']
        end
        app.add_analyser :format do |content|
          content.analyse(:identify)['format']
        end
        app.add_analyser :aspect_ratio do |content|
          attrs = content.analyse(:identify)
          attrs['width'].to_f / attrs['height']
        end
        app.add_analyser :portrait do |content|
          attrs = content.analyse(:identify)
          attrs['width'] <= attrs['height']
        end
        app.add_analyser :landscape do |content|
          !content.analyse(:portrait)
        end
        app.add_analyser :image do |content|
          begin
            content.analyse(:identify)
            true
          rescue Shell::CommandFailed
            false
          end
        end

        # Aliases
        app.define(:portrait?) { portrait }
        app.define(:landscape?) { landscape }
        app.define(:image?) { image }

        # Generators
        app.add_generator :convert, ImageMagick::Generators::Convert.new(command_line)
        app.add_generator :plain, ImageMagick::Generators::Plain.new
        app.add_generator :plasma, ImageMagick::Generators::Plasma.new
        app.add_generator :text, ImageMagick::Generators::Text.new

        # Processors
        app.add_processor :convert, Processors::Convert.new(command_line)
        app.add_processor :thumb, Processors::Thumb.new
        app.add_processor :encode, Processors::Encode.new
        app.add_processor :rotate do |content, amount, opts={}|
          content.process!(:convert, "-rotate #{amount}#{opts['qualifier']}")
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

