module Dragonfly
  module ImageMagick
    class Encoder

      include Configurable
      include Utils

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

      def encode(temp_object, format, args='')
        format = format.to_s.downcase
        throw :unable_to_handle unless supported_formats.include?(format.to_sym)
        details = identify(temp_object)

        if details[:format] == format.to_sym && args.empty?
          temp_object
        else
          convert(temp_object, args, format)
        end
      end

    end
  end
end
