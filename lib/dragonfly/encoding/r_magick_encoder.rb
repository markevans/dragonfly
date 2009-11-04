require 'rmagick'

module Dragonfly
  module Encoding
    
    class RMagickEncoder < Base
      
      include Configurable
      
      configurable_attr :default_mime_type, 'image/jpeg'
      
      def encode(image, mime_type, encoding={})
        mime_type ||= default_mime_type
        encoded_image = Magick::Image.from_blob(image.data).first
        encoded_image.format = MimeTypes.extension_for(mime_type)
        encoded_image.to_blob
      end
      
    end
    
  end
end
