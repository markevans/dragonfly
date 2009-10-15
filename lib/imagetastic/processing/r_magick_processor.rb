require 'rmagick'

module Imagetastic
  module Processing

    module RMagickProcessor
      
      def resize(temp_object, opts={})
        rmagick_image(temp_object).change_geometry!(opts[:geometry]) do |cols, rows, img|
         img.resize!(cols, rows)
        end.to_blob
      end

      def vignette(temp_object, opts={})
        x      = opts[:x].to_f      || temp_object.width  * 0.1
        y      = opts[:y].to_f      || temp_object.height * 0.1
        radius = opts[:radius].to_f ||  0.0
        sigma  = opts[:sigma].to_f  || 10.0

        rmagick_image(temp_object).vignette(x, y, radius, sigma).to_blob
      end
      
      private
      
      def rmagick_image(temp_object)
        Magick::Image.from_blob(temp_object.data).first
      end

    end

  end
end
