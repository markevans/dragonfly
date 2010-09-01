require 'RMagick'

module Dragonfly
  module Processing
    class RMagickProcessor

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

      # Geometry string patterns
      RESIZE_GEOMETRY         = /^\d*x\d*[><%^!]?$|^\d+@$/ # e.g. '300x200!'
      CROPPED_RESIZE_GEOMETRY = /^(\d+)x(\d+)#(\w{1,2})?$/ # e.g. '20x50#ne'
      CROP_GEOMETRY           = /^(\d+)x(\d+)([+-]\d+)?([+-]\d+)?(\w{1,2})?$/ # e.g. '30x30+10+10'
      THUMB_GEOMETRY = Regexp.union RESIZE_GEOMETRY, CROPPED_RESIZE_GEOMETRY, CROP_GEOMETRY

      include RMagickUtils
      include Configurable
      
      configurable_attr :use_filesystem, true

      def crop(temp_object, opts={})
        x       = opts[:x].to_i
        y       = opts[:y].to_i
        gravity = GRAVITIES[opts[:gravity]] || Magick::ForgetGravity
        width   = opts[:width].to_i
        height  = opts[:height].to_i

        rmagick_image(temp_object) do |image|
          # RMagick throws an error if the cropping area is bigger than the image,
          # when the gravity is something other than nw
          width  = image.columns - x if x + width  > image.columns
          height = image.rows    - y if y + height > image.rows
          image.crop(gravity, x, y, width, height)
        end
      end

      def flip(temp_object)
        rmagick_image(temp_object) do |image|
          image.flip!
        end
      end

      def flop(temp_object)
        rmagick_image(temp_object) do |image|
          image.flop!
        end
      end

      def greyscale(temp_object, opts={})
        depth = opts[:depth] || 256
        rmagick_image(temp_object) do |image|
          image.quantize(depth, Magick::GRAYColorspace)
        end
      end
      alias grayscale greyscale

      def resize(temp_object, geometry)
        rmagick_image(temp_object) do |image|
          image.change_geometry!(geometry) do |cols, rows, img|
           img.resize!(cols, rows)
          end
        end
      end

      def resize_and_crop(temp_object, opts={})
        rmagick_image(temp_object) do |image|

          width   = opts[:width] ? opts[:width].to_i : image.columns
          height  = opts[:height] ? opts[:height].to_i : image.rows
          gravity = GRAVITIES[opts[:gravity]] || Magick::CenterGravity

          image.crop_resized(width, height, gravity)
        end
      end

      def rotate(temp_object, amount, opts={})
        args = [amount.to_f]
        args << opts[:qualifier] if opts[:qualifier]
        rmagick_image(temp_object) do |image|
          image.background_color = opts[:background_colour] if opts[:background_colour]
          image.background_color = opts[:background_color] if opts[:background_color]
          image.rotate(*args) || temp_object
        end
      end

      def thumb(temp_object, geometry)
        case geometry
        when RESIZE_GEOMETRY
          resize(temp_object, geometry)
        when CROPPED_RESIZE_GEOMETRY
          resize_and_crop(temp_object, :width => $1, :height => $2, :gravity => $3)
        when CROP_GEOMETRY
          crop(temp_object,
            :width => $1,
            :height => $2,
            :x => $3,
            :y => $4,
            :gravity => $5
          )
        else raise ArgumentError, "Didn't recognise the geometry string #{geometry}"
        end
      end

      def vignette(temp_object, opts={})
        x      = opts[:x].to_f      || temp_object.width  * 0.1
        y      = opts[:y].to_f      || temp_object.height * 0.1
        radius = opts[:radius].to_f ||  0.0
        sigma  = opts[:sigma].to_f  || 10.0

        rmagick_image(temp_object) do |image|
          image.vignette(x, y, radius, sigma)
        end
      end

    end
  end
end
