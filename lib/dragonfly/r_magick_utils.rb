module Dragonfly
  module RMagickUtils
    
    private
    
    def rmagick_image(temp_object, &block)
      image = Magick::Image.from_blob(temp_object.data).first
      result = block[image]
      case result
      when Magick::Image, Magick::ImageList
        content = result.to_blob
        result.destroy!
      else
        content = result
      end
      image.destroy! unless image.destroyed?
      content
    rescue Magick::ImageMagickError => e
      log.warn("Unable to handle content in #{self.class} - got:\n#{e}")
      throw :unable_to_handle
    end
    
  end
end
