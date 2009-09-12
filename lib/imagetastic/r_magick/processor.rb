require 'rmagick'

module Imagetastic
  module RMagick

    class Processor < Processing::Base
      
      def resize(image, opts={})
        processed_image_data = Magick::Image.from_blob(image.data).first.scale(opts[:scale].to_f).to_blob
        Imagetastic::TempObject.new(processed_image_data)
      end

    end

  end
end
