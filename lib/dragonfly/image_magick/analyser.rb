module Dragonfly
  module ImageMagick
    class Analyser

      include Configurable
      include Utils

      def width(temp_object)
        identify(temp_object)[:width]
      end

      def height(temp_object)
        identify(temp_object)[:height]
      end

      def aspect_ratio(temp_object)
        attrs = identify(temp_object)
        attrs[:width].to_f / attrs[:height]
      end

      def portrait?(temp_object)
        attrs = identify(temp_object)
        attrs[:width] <= attrs[:height]
      end
      alias portrait portrait?

      def landscape?(temp_object)
        attrs = identify(temp_object)
        attrs[:width] >= attrs[:height]
      end
      alias landscape landscape?

      def depth(temp_object)
        identify(temp_object)[:depth]
      end

      def number_of_colours(temp_object)
        details = raw_identify(temp_object, '-verbose -unique')
        details[/Colors: (\d+)/, 1].to_i
      end
      alias number_of_colors number_of_colours

      def format(temp_object)
        identify(temp_object)[:format]
      end
      
      def image?(temp_object)
        !!catch(:unable_to_handle){ identify(temp_object) }
      end

    end
  end
end
