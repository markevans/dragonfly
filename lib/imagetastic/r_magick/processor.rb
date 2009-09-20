require 'rmagick'

module Imagetastic
  module RMagick

    class Processor < Processing::Base
      
      def resize(temp_object, opts={})
        image = Magick::Image.from_blob(temp_object.data).first
        image.change_geometry!(opts[:geometry]) do |cols, rows, img|
         img.resize!(cols, rows)
        end.to_blob
      end

    end

  end
end
