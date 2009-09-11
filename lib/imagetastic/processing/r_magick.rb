require 'rmagick'

module Imagetastic
  module Processing
    module RMagick

      class Encoder
        
        include Utils
        
        def encode(image, mime_type, encoding={})
          encoded_image = Magick::Image.from_blob(image.data).first
          encoded_image.format = extension_from_mime_type(mime_type)
          Imagetastic::Image.new(encoded_image.to_blob)
        end
        
      end

      class Processor < Processor

        def resize(image, opts={})
          processed_image_data = Magick::Image.from_blob(image.data).first.scale(opts[:scale].to_f).to_blob
          Imagetastic::Image.new(processed_image_data)
        end

      end

      class Analyser

        def get_dimensions(file)
          image = Magick::Image.read(file.local_path).first
          [image.columns, image.rows]
        end

      end

    end
  end
end
