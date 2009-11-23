require 'rmagick'

module Dragonfly
  module Processing

    class RMagickProcessor < Base
      
      GRAVITY_MAPPINGS = {
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
      
      def crop(temp_object, opts={})
        x       = opts[:x].to_i
        y       = opts[:y].to_i
        gravity = GRAVITY_MAPPINGS[opts[:gravity]] || Magick::ForgetGravity
        width   = opts[:width].to_i
        height  = opts[:height].to_i

        image = rmagick_image(temp_object)

        # RMagick throws an error if the cropping area is bigger than the image,
        # when the gravity is something other than nw
        width  = image.columns - x if x + width  > image.columns
        height = image.rows    - y if y + height > image.rows

        image.crop(gravity, x, y, width, height).to_blob
      end
      
      def generate(width, height)
        image = Magick::Image.new(width, height)
        num_points = 7
        args = []
        num_points.times do
          args << rand(width)
          args << rand(height)
          args << "rgb(#{rand(256)},#{rand(256)},#{rand(256)})"
        end
        image = image.sparse_color(Magick::ShepardsColorInterpolate, *args)
        image.format = 'png'
        image.to_blob
      end
      
      def resize(temp_object, opts={})
        rmagick_image(temp_object).change_geometry!(opts[:geometry]) do |cols, rows, img|
         img.resize!(cols, rows)
        end.to_blob
      end

      def resize_and_crop(temp_object, opts={})
        image = rmagick_image(temp_object)
        
        width   = opts[:width] ? opts[:width].to_i : image.columns
        height  = opts[:height] ? opts[:height].to_i : image.rows
        gravity = GRAVITY_MAPPINGS[opts[:gravity]] || Magick::CenterGravity

        image.resize_to_fill(width, height, gravity).to_blob
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
      end

    end

  end
end
