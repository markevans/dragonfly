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
          c.define_job Processing::RMagickProcessor::THUMB_GEOMETRY do |geometry|
            process :thumb, geometry
            encode app.default_format if app.default_format
          end
          c.define_job Processing::RMagickProcessor::THUMB_GEOMETRY, Symbol do |geometry, format|
            process :thumb, geometry
            encode format
          end
          c.define_job Symbol do |format|
            encode format
          end
          c.define_job :rotate, Numeric do |_, amount|
            process :rotate, :amount => amount, :background_colour => '#0000'
            encode app.default_format if app.default_format
          end
          c.define_job :rotate, Numeric, Symbol do |_, amount, format|
            process :rotate, :amount => amount, :background_colour => '#0000'
            encode format
          end
        end
    
      end
    
    end  
  end
end
