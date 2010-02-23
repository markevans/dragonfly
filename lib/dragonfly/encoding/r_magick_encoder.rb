require 'RMagick'

module Dragonfly
  module Encoding
    
    class RMagickEncoder < Base
      
      SUPPORTED_FORMATS = Magick.formats.select{|k,v| v =~ /.*rw./ }.map{|f| f.first.downcase }
      
      def encode(image, format, encoding={})
        format = format.to_s.downcase
        throw :unable_to_handle unless SUPPORTED_FORMATS.include?(format)
        encoded_image = Magick::Image.from_blob(image.data).first
        if encoded_image.format.downcase == format
          image # do nothing
        else
          encoded_image.format = format
          encoded_image.to_blob
        end
      end
      
    end
    
  end
end
