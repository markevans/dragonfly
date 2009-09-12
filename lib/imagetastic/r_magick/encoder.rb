require 'rmagick'

module Imagetastic
  module RMagick
    
    class Encoder < Encoding::Base
      
      include Utils
      include Configurable
      
      configurable_attr :default_mime_type, 'image/jpeg'
      
      def encode(image, mime_type, encoding={})
        mime_type ||= default_mime_type
        encoded_image = Magick::Image.from_blob(image.data).first
        encoded_image.format = extension_from_mime_type(mime_type)
        Imagetastic::TempObject.new(encoded_image.to_blob)
      end
      
    end
    
  end
end
