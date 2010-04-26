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
          c.parameters.configure do |p|
            p.default_format = :jpg
            # Standard resizing like '30x40!', etc.
            p.add_shortcut(Symbol) do |format|
              {:format => format}
            end
            p.add_shortcut(/^\d*x\d*[><%^!]?$|^\d+@$/) do |geometry, match_data|
              {
                :processing_method => :resize,
                :processing_options => {:geometry => geometry}
              }
            end
            # Cropped resizing like '20x50#ne'
            p.add_shortcut(/^(\d+)x(\d+)#(\w{1,2})?/) do |geometry, match_data|
              {
                :processing_method => :resize_and_crop,
                :processing_options => {:width => match_data[1], :height => match_data[2], :gravity => match_data[3]}
              }
            end
            # Cropping like '30x30+10+10ne'
            p.add_shortcut(/^(\d+)x(\d+)([+-]\d+)([+-]\d+)(\w{1,2})?/) do |geometry, match_data|
              {
                :processing_method => :crop,
                :processing_options => {
                  :width => match_data[1],
                  :height => match_data[2],
                  :x => match_data[3],
                  :y => match_data[4],
                  :gravity => match_data[5]
                }
              }
            end
            p.add_shortcut(/^\d*x/, Symbol) do |geometry, format|
              p.hash_from_shortcut(geometry).merge(:format => format)
            end
            p.add_shortcut(:rotate, Numeric) do |_, amount|
              {
                :processing_method => :rotate,
                :processing_options => {:amount => amount, :background_colour => '#0000'}
              }
            end
            p.add_shortcut(:rotate, Numeric, Symbol) do |a, b, format|
              p.hash_from_shortcut(a,b).merge(:format => format)
            end
          end
        end
    
      end
    
    end  
  end
end
