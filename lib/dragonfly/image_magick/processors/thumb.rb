module Dragonfly
  module ImageMagick
    module Processors
      class Thumb < Base

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

        def call(temp_object, geometry)
          case geometry
          when RESIZE_GEOMETRY
            resize(temp_object, geometry)
          when CROPPED_RESIZE_GEOMETRY
            resize_and_crop(temp_object, 'width' => $1, 'height' => $2, 'gravity' => $3)
          when CROP_GEOMETRY
            crop(temp_object,
              'width' => $1,
              'height' => $2,
              'x' => $3,
              'y' => $4,
              'gravity' => $5
            )
          else raise ArgumentError, "Didn't recognise the geometry string #{geometry}"
          end
        end

        def resize(temp_object, geometry)
          command_line.convert(temp_object.path, "-resize #{geometry}")
        end

        def crop(temp_object, opts={})
          width   = opts['width']
          height  = opts['height']
          gravity = GRAVITIES[opts['gravity']]
          x       = "#{opts['x'] || 0}"
          x = '+' + x unless x[/^[+-]/]
          y       = "#{opts['y'] || 0}"
          y = '+' + y unless y[/^[+-]/]

          command_line.convert(temp_object.path, "#{"-gravity #{gravity} " if gravity}-crop #{width}x#{height}#{x}#{y} +repage")
        end

        def resize_and_crop(temp_object, opts={})
          w, h = command_line.identify(temp_object.path, "-ping -format '%w %h'").split unless opts['width'] && opts['height']
          width = opts['width'] || w
          height = opts['height'] || h
          gravity = GRAVITIES[opts['gravity'] || 'c']

          command_line.convert(temp_object.path, "-resize #{width}x#{height}^^ -gravity #{gravity} -crop #{width}x#{height}+0+0 +repage")
        end

      end
    end
  end
end
