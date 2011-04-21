module Dragonfly
  module ImageMagick

    # ImageMagick Config is a saved configuration for Dragonfly apps, which does the following:
    # - registers an imagemagick analyser
    # - registers an imagemagick processor
    # - registers an imagemagick encoder
    # - adds thumb shortcuts like '280x140!', etc.
    # Look at the source code for apply_configuration to see exactly how it configures the app.
    module Config

      def self.apply_configuration(app, opts={})
        app.configure do |c|
          c.analyser.register(ImageMagick::Analyser)
          c.processor.register(ImageMagick::Processor)
          c.encoder.register(ImageMagick::Encoder)
          c.generator.register(ImageMagick::Generator)

          c.job :thumb do |geometry, format|
            process :thumb, geometry
            encode format if format
          end
          c.job :gif do
            encode :gif
          end
          c.job :jpg do
            encode :jpg
          end
          c.job :png do
            encode :png
          end
          c.job :strip do
            process :strip
          end
          c.job :convert do |args, format|
            process :convert, args, format
          end
        end

      end

    end
  end
end
