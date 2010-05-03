require 'RMagick'

module Dragonfly
  module Processing
    class RMagickProcessor < Base
      
      GRAVITIES = {
        'nw' => Magick::NorthWestGravity,
        'n'  => Magick::NorthGravity,
        'ne' => Magick::NorthEastGravity,
        'w'  => Magick::WestGravity,
        'c'  => Magick::CenterGravity,
        'e'  => Magick::EastGravity,
        'sw' => Magick::SouthWestGravity,
        's'  => Magick::SouthGravity,
        'se' => Magick::SouthEastGravity
      }

      def generate(width, height, format='png')
        image = Magick::Image.read("plasma:fractal"){self.size = "#{width}x#{height}"}.first
        image.format = format.to_s
        image.to_blob
      end
      
      # Processing methods
      
      def crop(temp_object, opts={})
        x       = opts[:x].to_i
        y       = opts[:y].to_i
        gravity = GRAVITIES[opts[:gravity]] || Magick::ForgetGravity
        width   = opts[:width].to_i
        height  = opts[:height].to_i

        image = rmagick_image(temp_object)

        # RMagick throws an error if the cropping area is bigger than the image,
        # when the gravity is something other than nw
        width  = image.columns - x if x + width  > image.columns
        height = image.rows    - y if y + height > image.rows

        image.crop(gravity, x, y, width, height).to_blob
      end
      
      def greyscale(temp_object, opts={})
        depth = opts[:depth] || 256
        rmagick_image(temp_object).quantize(depth, Magick::GRAYColorspace).to_blob
      end
      alias grayscale greyscale
      
      def resize(temp_object, opts={})
        rmagick_image(temp_object).change_geometry!(opts[:geometry]) do |cols, rows, img|
         img.resize!(cols, rows)
        end.to_blob
      end

      def resize_and_crop(temp_object, opts={})
        image = rmagick_image(temp_object)
        
        width   = opts[:width] ? opts[:width].to_i : image.columns
        height  = opts[:height] ? opts[:height].to_i : image.rows
        gravity = GRAVITIES[opts[:gravity]] || Magick::CenterGravity

        image.crop_resized(width, height, gravity).to_blob
      end

      def rotate(temp_object, opts={})
        if opts[:amount]
          args = [opts[:amount].to_f]
          args << opts[:qualifier] if opts[:qualifier]
          image = rmagick_image(temp_object)
          image.background_color = opts[:background_colour] if opts[:background_colour]
          image.background_color = opts[:background_color] if opts[:background_color]
          rotated_image = image.rotate(*args)
          rotated_image ? rotated_image.to_blob : temp_object
        else
          temp_object
        end
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
      rescue Magick::ImageMagickError => e
        log.warn("Unable to handle content in #{self.class} - got:\n#{e}")
        throw :unable_to_handle
      end

    end
  end
end
