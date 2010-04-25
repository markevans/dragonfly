require 'RMagick'

module Dragonfly
  module Processing

    class RMagickTextProcessor < Base
      
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
            
      def text(temp_object, opts={})
        opts = HashWithCssStyleKeys[opts]
        
        draw = Magick::Draw.new
        draw.gravity = Magick::CenterGravity
        draw.text_antialias = true
        
        # Settings
        draw.font         = opts[:font] if opts[:font]
        draw.font_family  = opts[:font_family] if opts[:font_family]
        draw.pointsize    = opts[:font_size].to_f if opts[:font_size]
        draw.fill         = opts[:color] if opts[:color]
        draw.stroke       = opts[:stroke_color] if opts[:stroke_color]
        draw.font_style   = FONT_STYLES[opts[:font_style]] if opts[:font_style]
        draw.font_stretch = FONT_STRETCHES[opts[:font_stretch]] if opts[:font_stretch]
        draw.font_weight  = FONT_WEIGHTS[opts[:font_weight]] if opts[:font_weight]

        text = temp_object.data

        # Calculate dimensions
        metrics = draw.get_type_metrics(text)
        width, height = metrics.width, metrics.height

        pt, pr, pb, pl = parse_padding_string(opts[:padding]) if opts[:padding]
        padding_top    = opts[:padding_top]    || pt || 0
        padding_right  = opts[:padding_right]  || pr || 0
        padding_bottom = opts[:padding_bottom] || pb || 0
        padding_left   = opts[:padding_left]   || pl || 0

        # Hack - for small font sizes, the width seems to be affected by rounding errors
        padding_right += 2

        total_width = padding_left + width + padding_right
        total_height = padding_top + height + padding_bottom

        # Draw the background
        image = Magick::Image.new(total_width, total_height){
          self.background_color = opts[:background_color] || 'transparent'
        }
        # Draw the text
        draw.annotate(image, width, height, padding_left, padding_top, text)
        # Output image as string
        image.format = 'png'
        image.to_blob
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

    end

  end
end
