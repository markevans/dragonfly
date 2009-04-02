require 'rmagick'

module Imagetastic
  module ImageProcessing
    module ImageMagick

      class FormatConverter
      end
  
      class ImageProcessor
    
        def resize(image_data, opts={})
          Magick::Image.from_blob(image_data).first.scale(opts[:scale].to_f).to_blob
        end
    
      end
  
      class ImageAnalyser

        def get_dimensions(file)
          image = Magick::Image.read(file.local_path).first
          [image.columns, image.rows]
        end
    
      end

    end
  end
end
