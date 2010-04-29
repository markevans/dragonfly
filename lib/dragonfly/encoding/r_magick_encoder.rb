require 'RMagick'

module Dragonfly
  module Encoding
    
    class RMagickEncoder < Base
      
      SUPPORTED_FORMATS = Magick.formats.select{|k,v| v =~ /.*rw./ }.map{|f| f.first.downcase }
      
      def encode(image, format, encoding={})
        format = format.to_s.downcase
        throw :unable_to_handle unless SUPPORTED_FORMATS.include?(format)
        encoded_image = rmagick_image(image)
        if encoded_image.format.downcase == format
          image # do nothing
        else
          encoded_image.format = format
          encoded_image.to_blob
        end
      end
      
      private
      
      def rmagick_image(temp_object)
        Magick::Image.from_blob(temp_object.data).first
      rescue Magick::ImageMagickError => e
        log.warn("Unable to handle content in #{self.class} - got:\n#{e}")
        throw :unable_to_handle
      end

    end
    
  end
end
