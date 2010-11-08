module Dragonfly
  module Processing
    class ImageMagickProcessor

      GRAVITIES = {
        'nw' => 'NorthWest',
        'n'  => 'North',
        'ne' => 'NorthEast',
        'w'  => 'West',
        'c'  => 'Center',
        'e'  => 'East',
        'sw' => 'SouthWest',
        's'  => 'South',
        'se' => 'SouthEast'
      }
      
      # Geometry string patterns
      RESIZE_GEOMETRY         = /^\d*x\d*[><%^!]?$|^\d+@$/ # e.g. '300x200!'
      CROPPED_RESIZE_GEOMETRY = /^(\d+)x(\d+)#(\w{1,2})?$/ # e.g. '20x50#ne'
      CROP_GEOMETRY           = /^(\d+)x(\d+)([+-]\d+)?([+-]\d+)?(\w{1,2})?$/ # e.g. '30x30+10+10'
      THUMB_GEOMETRY = Regexp.union RESIZE_GEOMETRY, CROPPED_RESIZE_GEOMETRY, CROP_GEOMETRY
      
      include ImageMagickUtils
      
      def resize(temp_object, geometry)
        convert(temp_object, "-resize '#{geometry}'")
      end
      
      def crop(temp_object, opts={})
        width   = opts[:width]
        height  = opts[:height]
        gravity = GRAVITIES[opts[:gravity]]
        x       = "#{opts[:x] || 0}"
        x = '+' + x unless x[/^[+-]/]
        y       = "#{opts[:y] || 0}"
        y = '+' + y unless y[/^[+-]/]
      
        if gravity
          convert(temp_object, "-crop #{width}x#{height}#{x}#{y} -gravity #{gravity}")
        else
          convert(temp_object, "-crop #{width}x#{height}#{x}#{y}")
        end
      end
      
      def flip(temp_object)
        convert(temp_object, "-flip")
      end
      
      def flop(temp_object)
        convert(temp_object, "-flop")
      end
      
      def greyscale(temp_object)
        convert(temp_object, "-colorspace Gray")
      end
      alias grayscale greyscale
      
      def resize_and_crop(temp_object, opts={})
        attrs          = identify(temp_object)
        current_width  = attrs[:width].to_i
        current_height = attrs[:height].to_i
        
        width   = opts[:width]  ? opts[:width].to_i  : current_width
        height  = opts[:height] ? opts[:height].to_i : current_height
        gravity = GRAVITIES[opts[:gravity] || 'c']

        if width != current_width || height != current_height
          scale = [width / current_width.to_f, height / current_height.to_f].max
          temp_object = TempObject.new(resize(temp_object, "#{(scale * current_width + 0.5).to_i}x#{(scale * current_height + 0.5).to_i}"))
        end

        crop(temp_object, :width => width, :height => height, :gravity => gravity)
      end
      
      def rotate(temp_object, amount, opts={})
        convert(temp_object, "-rotate '#{amount}#{opts[:qualifier]}'")
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
      
    end
  end
end
