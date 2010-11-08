# :filename => filename,
# :format => format.downcase,
# :width => width,
# :height => height,
# :depth => depth,
# :image_class => image_class,
# :size => size

module Dragonfly
  module Analysis
    class ImageMagickAnalyser

      include ImageMagickUtils
      include Configurable

      def width(temp_object)
        safe_identify(temp_object)[:width].to_i
      end

      def height(temp_object)
        safe_identify(temp_object)[:height].to_i
      end

      def aspect_ratio(temp_object)
        attrs = safe_identify(temp_object)
        attrs[:width].to_f / attrs[:height].to_i
      end

      def portrait?(temp_object)
        attrs = safe_identify(temp_object)
        attrs[:width].to_i <= attrs[:height].to_i
      end

      def landscape?(temp_object)
        attrs = safe_identify(temp_object)
        attrs[:width].to_i >= attrs[:height].to_i
      end

      def depth(temp_object)
        safe_identify(temp_object)[:depth].to_i
      end

      def number_of_colours(temp_object)
        details = safe_identify(temp_object, '-verbose -unique')
        details.match(/Colors: ([0-9]+)/)[1].to_i
      end
      alias number_of_colors number_of_colours

      def format(temp_object)
        safe_identify(temp_object)[:format]
      end

      def safe_identify(temp_object, args='')
        begin
          identify(temp_object, args)
        rescue ShellCommandFailed
          throw :unable_to_handle
        end
      end

    end
  end
end
