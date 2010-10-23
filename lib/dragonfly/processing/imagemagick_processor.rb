require 'tempfile'

module Dragonfly
  module Processing
    class ImagemagickProcessor

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

      include Configurable
      
      configurable_attr :convert_command, "convert"

      def resize(temp_object, geometry)
        convert(temp_object, "-resize #{geometry}")
      end
      
      def crop(temp_object, opts={})
        width   = opts[:width]
        height  = opts[:height]
        gravity = GRAVITIES[opts[:gravity]]
        x       = opts[:x] || 0
        y       = opts[:y] || 0
        
        if gravity
          convert(temp_object, "-crop #{width}x#{height} -gravity #{gravity}")
        else
          convert(temp_object, "-crop #{width}x#{height} -gravity #{gravity}")
        end
      end

      def flip(temp_object)
        convert(temp_object, "-flip")
      end

      def flop(temp_object)
        convert(temp_object, "-flop")
      end

      def greyscale(temp_object, opts={})
        depth = opts[:depth] || 256
      end
      alias grayscale greyscale

      def resize_and_crop(temp_object, opts={})
      end

      def rotate(temp_object, amount, opts={})
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
      end
      
      def convert(temp_object, args)
        tempfile = new_tempfile
        command = "#{convert_command} #{args} #{temp_object.path} #{tempfile.path}"
        # puts command
        system command
        tempfile
      end
      
      private
      
      def new_tempfile(ext=nil)
        tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
        tempfile.binmode
        tempfile.close
        tempfile
      end
      
    end
  end
end
