require 'rmagick'

module Imagetastic
  module Encoding
    
    class RMagickEncoder < Base
      
      include Utils
      include Configurable
      
      configurable_attr :default_mime_type, 'image/jpeg'
      
      def encode(image, mime_type, encoding={})
        mime_type ||= default_mime_type
        encoded_image = Magick::Image.from_blob(image.data).first
        encoded_image.format = extension_from_mime_type(mime_type)
        encoded_image.to_blob
      end
      
    end
    
  end
end
