module Dragonfly
  module ImageMagick
    module Processors
      class Thumb

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

        def call(content, geometry)
          case geometry
          when RESIZE_GEOMETRY
            resize(content, geometry)
          when CROPPED_RESIZE_GEOMETRY
            resize_and_crop(content, 'width' => $1, 'height' => $2, 'gravity' => $3)
          when CROP_GEOMETRY
            crop(content,
              'width' => $1,
              'height' => $2,
              'x' => $3,
              'y' => $4,
              'gravity' => $5
            )
          else raise ArgumentError, "Didn't recognise the geometry string #{geometry}"
          end
        end

        private

        def resize(content, geometry)
          content.process!(:convert, "-resize #{geometry}")
        end

        def crop(content, opts={})
          raise ArgumentError, "you can't give a crop offset and gravity at the same time" if opts['x'] && opts['gravity']

          width   = opts['width']
          height  = opts['height']
          gravity = GRAVITIES[opts['gravity']]
          x       = "#{opts['x'] || 0}"
          x = '+' + x unless x[/^[+-]/]
          y       = "#{opts['y'] || 0}"
          y = '+' + y unless y[/^[+-]/]

          content.process!(:convert, "#{"-gravity #{gravity} " if gravity}-crop #{width}x#{height}#{x}#{y} +repage")
        end

        def resize_and_crop(content, opts={})
          attrs = content.analyse(:identify_basic) unless opts['width'] && opts['height']
          width = opts['width'] || attrs['width']
          height = opts['height'] || attrs['height']
          gravity = GRAVITIES[opts['gravity'] || 'c']

          content.process!(:convert, "-resize #{width}x#{height}^^ -gravity #{gravity} -crop #{width}x#{height}+0+0 +repage")
        end

      end
    end
  end
end
