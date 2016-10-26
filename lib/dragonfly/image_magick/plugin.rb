require 'dragonfly/image_magick/analysers/image_properties'
require 'dragonfly/image_magick/generators/convert'
require 'dragonfly/image_magick/generators/plain'
require 'dragonfly/image_magick/generators/plasma'
require 'dragonfly/image_magick/generators/text'
require 'dragonfly/image_magick/processors/convert'
require 'dragonfly/image_magick/processors/encode'
require 'dragonfly/image_magick/processors/thumb'

module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin registers an app with generators, analysers and processors.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin

      def call(app, opts={})
        # ENV
        app.env[:convert_command] = opts[:convert_command] || 'convert'
        app.env[:identify_command] = opts[:identify_command] || 'identify'

        # Analysers
        app.add_analyser :image_properties, ImageMagick::Analysers::ImageProperties.new
        app.add_analyser :width do |content|
          content.analyse(:image_properties)['width']
        end
        app.add_analyser :height do |content|
          content.analyse(:image_properties)['height']
        end
        app.add_analyser :format do |content|
          content.analyse(:image_properties)['format']
        end
        app.add_analyser :aspect_ratio do |content|
          attrs = content.analyse(:image_properties)
          attrs['width'].to_f / attrs['height']
        end
        app.add_analyser :portrait do |content|
          attrs = content.analyse(:image_properties)
          attrs['width'] <= attrs['height']
        end
        app.add_analyser :landscape do |content|
          !content.analyse(:portrait)
        end
        app.add_analyser :image do |content|
          begin
            content.analyse(:image_properties)['format'] != 'pdf'
          rescue Shell::CommandFailed
            false
          end
        end

        # Aliases
        app.define(:portrait?) { portrait }
        app.define(:landscape?) { landscape }
        app.define(:image?) { image }

        # Generators
        app.add_generator :convert, ImageMagick::Generators::Convert.new
        app.add_generator :plain, ImageMagick::Generators::Plain.new
        app.add_generator :plasma, ImageMagick::Generators::Plasma.new
        app.add_generator :text, ImageMagick::Generators::Text.new

        # Processors
        app.add_processor :convert, Processors::Convert.new
        app.add_processor :encode, Processors::Encode.new
        app.add_processor :thumb, Processors::Thumb.new
        app.add_processor :rotate do |content, amount|
          content.process!(:convert, "-rotate #{amount}")
        end

        # Extra methods
        app.define :identify do |cli_args=nil|
          shell_eval do |path|
            "#{app.env[:identify_command]} #{cli_args} #{path}"
          end
        end

      end

    end
  end
end

