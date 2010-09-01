module Dragonfly
  module Config

    # RMagick is a saved configuration for Dragonfly apps, which does the following:
    # - registers an rmagick analyser
    # - registers an rmagick processor
    # - registers an rmagick encoder
    # - adds thumb shortcuts like '280x140!', etc.
    # Look at the source code for apply_configuration to see exactly how it configures the app.
    module RMagick

      def self.apply_configuration(app, opts={})
        use_filesystem = opts.has_key?(:use_filesystem) ? opts[:use_filesystem] : true
        app.configure do |c|
          c.analyser.register(Analysis::RMagickAnalyser) do |a|
            a.use_filesystem = use_filesystem
          end
          c.processor.register(Processing::RMagickProcessor) do |p|
            p.use_filesystem = use_filesystem
          end
          c.encoder.register(Encoding::RMagickEncoder) do |e|
            e.use_filesystem = use_filesystem
          end
          c.generator.register(Generation::RMagickGenerator) do |g|
            g.use_filesystem = use_filesystem
          end
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
        end

      end

    end
  end
end
