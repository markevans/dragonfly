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
        RESIZE_GEOMETRY         = /\A\d*x\d*[><%^!]?\z|\A\d+@\z/ # e.g. '300x200!'
        CROPPED_RESIZE_GEOMETRY = /\A(\d+)x(\d+)#(\w{1,2})?\z/ # e.g. '20x50#ne'
        CROP_GEOMETRY           = /\A(\d+)x(\d+)([+-]\d+)?([+-]\d+)?(\w{1,2})?\z/ # e.g. '30x30+10+10'

        def update_url(url_attributes, geometry, opts={})
          format = opts['format']
          url_attributes.ext = format if format
        end

        def call(content, geometry, opts={})
          content.process!(:convert, args_for_geometry(geometry), opts)
        end

        def args_for_geometry(geometry)
          case geometry
          when RESIZE_GEOMETRY
            resize_args(geometry)
          when CROPPED_RESIZE_GEOMETRY
            resize_and_crop_args($1, $2, $3)
          when CROP_GEOMETRY
            crop_args(
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

        def resize_args(geometry)
          "-resize #{geometry}"
        end

        def crop_args(opts)
          raise ArgumentError, "you can't give a crop offset and gravity at the same time" if opts['x'] && opts['gravity']

          width   = opts['width']
          height  = opts['height']
          gravity = GRAVITIES[opts['gravity']]
          x       = "#{opts['x'] || 0}"
          x = '+' + x unless x[/\A[+-]/]
          y       = "#{opts['y'] || 0}"
          y = '+' + y unless y[/\A[+-]/]

          "#{"-gravity #{gravity} " if gravity}-crop #{width}x#{height}#{x}#{y} +repage"
        end

        def resize_and_crop_args(width, height, gravity)
          gravity = GRAVITIES[gravity || 'c']
          "-resize #{width}x#{height}^^ -gravity #{gravity} -crop #{width}x#{height}+0+0 +repage"
        end

      end
    end
  end
end

