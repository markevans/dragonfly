require 'RMagick'

module Dragonfly
  module Generation
    class RMagickGenerator

      FONT_STYLES = {
        'normal' => Magick::NormalStyle,
        'italic' => Magick::ItalicStyle,
        'oblique' => Magick::ObliqueStyle
      }

      FONT_STRETCHES = {
        'normal'          => Magick::NormalStretch,
        'semi-condensed'  => Magick::SemiCondensedStretch,
        'condensed'       => Magick::CondensedStretch,
        'extra-condensed' => Magick::ExtraCondensedStretch,
        'ultra-condensed' => Magick::UltraCondensedStretch,
        'semi-expanded'   => Magick::SemiExpandedStretch,
        'expanded'        => Magick::ExpandedStretch,
        'extra-expanded'  => Magick::ExtraExpandedStretch,
        'ultra-expanded'  => Magick::UltraExpandedStretch
      }

      FONT_WEIGHTS = {
        'normal'  => Magick::NormalWeight,
        'bold'    => Magick::BoldWeight,
        'bolder'  => Magick::BolderWeight,
        'lighter' => Magick::LighterWeight,
        '100'     => 100,
        '200'     => 200,
        '300'     => 300,
        '400'     => 400,
        '500'     => 500,
        '600'     => 600,
        '700'     => 700,
        '800'     => 800,
        '900'     => 900
      }

      # HashWithCssStyleKeys is solely for being able to access a hash
      # which has css-style keys (e.g. 'font-size') with the underscore
      # symbol version
      # @example
      #   opts = {'font-size' => '23px', :color => 'white'}
      #   opts = HashWithCssStyleKeys[opts]
      #   opts[:font_size]   # ===> '23px'
      #   opts[:color]       # ===> 'white'
      class HashWithCssStyleKeys < Hash
        def [](key)
          super || (
            str_key = key.to_s
            css_key = str_key.gsub('_','-')
            super(str_key) || super(css_key) || super(css_key.to_sym)
          )
        end
      end

      include RMagickUtils
      include Configurable
      configurable_attr :use_filesystem, true

      def plasma(width, height, format='png')
        image = Magick::Image.read("plasma:fractal"){self.size = "#{width}x#{height}"}.first
        image.format = format.to_s
        content = use_filesystem ? write_to_tempfile(image) : image.to_blob
        image.destroy!
        [
          content,
          {:format => format.to_sym, :name => "plasma.#{format}"}
        ]
      end

      def text(text_string, opts={})
        opts = HashWithCssStyleKeys[opts]

        draw = Magick::Draw.new
        draw.gravity = Magick::CenterGravity
        draw.text_antialias = true

        # Font size
        font_size = (opts[:font_size] || 12).to_i

        # Scale up the text for better quality -
        #  it will be reshrunk at the end
        s = scale_factor_for(font_size)

        # Settings
        draw.pointsize    = font_size * s
        draw.font         = opts[:font] if opts[:font]
        draw.font_family  = opts[:font_family] if opts[:font_family]
        draw.fill         = opts[:color] if opts[:color]
        draw.stroke       = opts[:stroke_color] if opts[:stroke_color]
        draw.font_style   = FONT_STYLES[opts[:font_style]] if opts[:font_style]
        draw.font_stretch = FONT_STRETCHES[opts[:font_stretch]] if opts[:font_stretch]
        draw.font_weight  = FONT_WEIGHTS[opts[:font_weight]] if opts[:font_weight]

        # Padding
        # NB the values are scaled up by the scale factor
        pt, pr, pb, pl = parse_padding_string(opts[:padding]) if opts[:padding]
        padding_top    = (opts[:padding_top]    || pt || 0) * s
        padding_right  = (opts[:padding_right]  || pr || 0) * s
        padding_bottom = (opts[:padding_bottom] || pb || 0) * s
        padding_left   = (opts[:padding_left]   || pl || 0) * s

        # Calculate (scaled up) dimensions
        metrics = draw.get_type_metrics(text_string)
        width, height = metrics.width, metrics.height

        scaled_up_width = padding_left + width + padding_right
        scaled_up_height = padding_top + height + padding_bottom

        # Draw the background
        image = Magick::Image.new(scaled_up_width, scaled_up_height){
          self.background_color = opts[:background_color] || 'transparent'
        }
        # Draw the text
        draw.annotate(image, width, height, padding_left, padding_top, text_string)

        # Scale back down again
        image.scale!(1/s)

        format = opts[:format] || :png
        image.format = format.to_s

        # Output image either as a string or a tempfile
        content = use_filesystem ? write_to_tempfile(image) : image.to_blob
        image.destroy!
        [
          content,
          {:format => format, :name => "text.#{format}"}
        ]
      end

      private

      # Use css-style padding declaration, i.e.
      # 10        (all sides)
      # 10 5      (top/bottom, left/right)
      # 10 5 10   (top, left/right, bottom)
      # 10 5 10 5 (top, right, bottom, left)
      def parse_padding_string(str)
        padding_parts = str.gsub('px','').split(/\s+/).map{|px| px.to_i}
        case padding_parts.size
        when 1
          p = padding_parts.first
          [p,p,p,p]
        when 2
          p,q = padding_parts
          [p,q,p,q]
        when 3
          p,q,r = padding_parts
          [p,q,r,q]
        when 4
          padding_parts
        else raise ArgumentError, "Couldn't parse padding string '#{str}' - should be a css-style string"
        end
      end

      def scale_factor_for(font_size)
        # Scale approximately to 64 if below
        min_size = 64
        if font_size < min_size
          (min_size.to_f / font_size).ceil
        else
          1
        end.to_f
      end

    end

  end
end
