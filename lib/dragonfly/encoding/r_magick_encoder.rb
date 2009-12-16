require 'RMagick'

module Dragonfly
  module Encoding
    
    class RMagickEncoder < Base
      
      SUPPORTED_FORMATS = Magick.formats.select{|k,v| v =~ /.*rw./ }.map{|f| f.first.downcase }
      
      def encode(image, format, encoding={})
        throw :unable_to_handle unless SUPPORTED_FORMATS.include?(format.to_s)
        encoded_image = Magick::Image.from_blob(image.data).first
        encoded_image.format = format.to_s
        encoded_image.to_blob
      end
      
    end
    
  end
end
