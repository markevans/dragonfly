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
      
      def aspect_ratio(image)
        rmagick_data = rmagick_image(image)
        rmagick_data.columns.to_f / rmagick_data.rows
      end
      
      def depth(image)
        rmagick_image(image).depth
      end
      
      def number_of_colours(image)
        rmagick_image(image).number_colors
      end
      alias number_of_colors number_of_colours

      def format(image)
        rmagick_image(image).format.downcase.to_sym
      end
      
      private
      
      def rmagick_image(image)
        Magick::Image.from_blob(image.data).first
      rescue Magick::ImageMagickError => e
        log.warn("Unable to handle content in #{self.class} - got:\n#{e}")
        throw :unable_to_handle
      end
      
    end
    
  end
end
