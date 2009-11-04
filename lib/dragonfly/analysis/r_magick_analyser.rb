require 'rmagick'

module Dragonfly
  module Analysis
    
    module RMagickAnalyser
      
      def width(image)
        rmagick_image(image).columns
      end
      
      def height(image)
        rmagick_image(image).rows
      end
      
      def mime_type(image)
        MimeTypes.mime_type_for(rmagick_image(image).format)
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
        Magick::ImageList.new(image.path).first
      end
      
    end
    
  end
end
