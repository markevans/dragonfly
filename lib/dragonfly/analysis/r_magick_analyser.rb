require 'RMagick'

module Dragonfly
  module Analysis
    class RMagickAnalyser

      include Loggable
      include RMagickUtils
      include Configurable

      configurable_attr :use_filesystem, true

      def width(temp_object)
        ping_rmagick_image(temp_object) do |image|
          image.columns
        end
      end

      def height(temp_object)
        ping_rmagick_image(temp_object) do |image|
          image.rows
        end
      end

      def aspect_ratio(temp_object)
        ping_rmagick_image(temp_object) do |image|
          image.columns.to_f / image.rows
        end
      end

      def portrait?(temp_object)
        ping_rmagick_image(temp_object) do |image|
          image.columns <= image.rows
        end
      end

      def landscape?(temp_object)
        ping_rmagick_image(temp_object) do |image|
          image.columns >= image.rows
        end
      end

      def depth(temp_object)
        rmagick_image(temp_object) do |image|
          image.depth
        end
      end

      def number_of_colours(temp_object)
        rmagick_image(temp_object) do |image|
          image.number_colors
        end
      end
      alias number_of_colors number_of_colours

      def format(temp_object)
        ping_rmagick_image(temp_object) do |image|
          image.format.downcase.to_sym
        end
      end

    end
  end
end
