require 'rmagick'

module Dragonfly
  module Encoding
    
    class RMagickEncoder < Base
      
      def encode(image, format, encoding={})
        encoded_image = Magick::Image.from_blob(image.data).first
        encoded_image.format = format.to_s
        encoded_image.to_blob
      end
      
    end
    
  end
end
