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
          c.define_job do
            process :thumb, opts[:geometry]
            encode opts[:format] || app.default_format
          end
          c.define_job :encode do
            encode opts[:format]
          end
          c.define_job :rotate do
            process :rotate, :amount => opts[:amount], :background_colour => '#0000'
            encode opts[:format] || app.default_format
          end
        end
    
      end
    
    end  
  end
end
