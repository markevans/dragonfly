require 'RMagick'

module Dragonfly
  module Analysis
    
    class RMagickAnalyser < Base
      
      def width(image)
        rmagick_image(image).columns
      end
      
      def height(image)
        rmagick_image(image).rows
      end
      
      def depth(image)
        rmagick_image(image).depth
      end
      
      def number_of_colours(image)
        rmagick_image(image).number_colors
      end
      alias number_of_colors number_of_colours
      
      private
      
      def rmagick_image(image)
        Magick::Image.from_blob(image.data).first
      end
      
    end
    
  end
end
