require 'RMagick'

module Dragonfly
  module Encoding
    class RMagickEncoder

      include Configurable
      include RMagickUtils

      configurable_attr :supported_formats, [
        :ai,
        :bmp,
        :eps,
        :gif,
        :gif87,
        :ico,
        :j2c,
        :jp2,
        :jpeg,
        :jpg,
        :pbm,
        :pcd,
        :pct,
        :pcx,
        :pdf,
        :pict,
        :pjpeg,
        :png,
        :png24,
        :png32,
        :png8,
        :pnm,
        :ppm,
        :ps,
        :psd,
        :ras,
        :tga,
        :tiff,
        :wbmp,
        :xbm,
        :xpm,
        :xwd
      ]
      configurable_attr :use_filesystem, true

      def encode(temp_object, format, encoding={})
        format = format.to_s.downcase
        throw :unable_to_handle unless supported_formats.include?(format.to_sym)
        rmagick_image(temp_object) do |image|
          if image.format.downcase == format
            temp_object # do nothing
          else
            image.format = format
            image
          end
        end
      end

    end
  end
end
