require 'tempfile'

module Dragonfly
  module RMagickUtils

    private

    # Requires the extended object to respond to 'use_filesystem'
    def rmagick_image(temp_object, &block)
      imagelist = use_filesystem ? Magick::Image.read(temp_object.path) : Magick::Image.from_blob(temp_object.data)
      image = imagelist.first
      result = block.call(image)
      case result
      when Magick::Image, Magick::ImageList
        content = use_filesystem ? write_to_tempfile(result) : result.to_blob
        result.destroy!
      else
        content = result
      end
      image.destroy!
      content
    rescue Magick::ImageMagickError => e
      log.warn("Unable to handle content in #{self.class} - got:\n#{e}")
      throw :unable_to_handle
    end

    def ping_rmagick_image(temp_object, &block)
      imagelist = use_filesystem ? Magick::Image.ping(temp_object.path) : Magick::Image.from_blob(temp_object.data)
      image = imagelist.first
      result = block.call(image)
      image.destroy!
      result
    rescue Magick::ImageMagickError => e
      log.warn("Unable to handle content in #{self.class} - got:\n#{e}")
      throw :unable_to_handle
    end

    def write_to_tempfile(rmagick_image)
      tempfile = Tempfile.new('dragonfly')
      tempfile.close
      rmagick_image.write(tempfile.path)
      tempfile
    end

  end
end
