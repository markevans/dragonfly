require 'rmagick'

module Imagetastic
  module Analysis
    
    module RMagickAnalyser
      
      include Utils
      
      def width
        image.columns
      end
      
      def height
        image.rows
      end
      
      def mime_type
        mime_type_from_extension(image.format)
      end
      
      def depth
        image.depth
      end
      
      def number_of_colours
        image.number_colors
      end
      
      private
      
      def image
        @image ||= Magick::ImageList.new(self.path).first
      end
      
    end
    
  end
end
