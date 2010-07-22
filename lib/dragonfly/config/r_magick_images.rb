module Dragonfly
  module Config
    
    # RMagickImages is a saved configuration for Dragonfly apps, which does the following:
    # - registers an rmagick analyser
    # - registers an rmagick processor
    # - registers an rmagick encoder
    # - adds parameter shortcuts like '280x140!', etc.
    # Look at the source code for apply_configuration to see exactly how it configures the app.
    module RMagickImages
    
      def self.apply_configuration(app)
        app.configure do |c|
          c.register_analyser(Analysis::FileCommandAnalyser)
          c.register_analyser(Analysis::RMagickAnalyser)
          c.register_processor(Processing::RMagickProcessor)
          c.register_encoder(Encoding::RMagickEncoder)
          c.register_generator(Generation::RMagickGenerator)
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
