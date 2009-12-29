require 'RMagick'

module Dragonfly
  module Processing

    class RMagickProcessor < Base
      
      GRAVITIES = {
        'nw' => Magick::NorthWestGravity,
        'n'  => Magick::NorthGravity,
        'ne' => Magick::NorthEastGravity,
        'w'  => Magick::WestGravity,
        'c'  => Magick::CenterGravity,
        'e'  => Magick::EastGravity,
        'sw' => Magick::SouthWestGravity,
        's'  => Magick::SouthGravity,
        'se' => Magick::SouthEastGravity
      }
      
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
      
      
      # Processing methods
      
      def crop(temp_object, opts={})
        x       = opts[:x].to_i
        y       = opts[:y].to_i
        gravity = GRAVITIES[opts[:gravity]] || Magick::ForgetGravity
        width   = opts[:width].to_i
        height  = opts[:height].to_i

        image = rmagick_image(temp_object)

        # RMagick throws an error if the cropping area is bigger than the image,
        # when the gravity is something other than nw
        width  = image.columns - x if x + width  > image.columns
        height = image.rows    - y if y + height > image.rows

        image.crop(gravity, x, y, width, height).to_blob
      end
      
      def generate(width, height, format='png')
        image = Magick::Image.read("plasma:fractal"){self.size = "#{width}x#{height}"}.first
        image.format = format.to_s
        image.to_blob
      end
      
      def resize(temp_object, opts={})
        rmagick_image(temp_object).change_geometry!(opts[:geometry]) do |cols, rows, img|
         img.resize!(cols, rows)
        end.to_blob
      end

      def resize_and_crop(temp_object, opts={})
        image = rmagick_image(temp_object)
        
        width   = opts[:width] ? opts[:width].to_i : image.columns
        height  = opts[:height] ? opts[:height].to_i : image.rows
        gravity = GRAVITIES[opts[:gravity]] || Magick::CenterGravity

        image.crop_resized(width, height, gravity).to_blob
      end

      def rotate(temp_object, opts={})
        if opts[:amount]
          args = [opts[:amount].to_f]
          args << opts[:qualifier] if opts[:qualifier]
          image = rmagick_image(temp_object)
          image.background_color = opts[:background_colour] if opts[:background_colour]
          image.background_color = opts[:background_color] if opts[:background_color]
          rotated_image = image.rotate(*args)
          rotated_image ? rotated_image.to_blob : temp_object
        else
          temp_object
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
        draw.pointsize    = opts[:font_size] if opts[:font_size]
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

      def vignette(temp_object, opts={})
        x      = opts[:x].to_f      || temp_object.width  * 0.1
        y      = opts[:y].to_f      || temp_object.height * 0.1
        radius = opts[:radius].to_f ||  0.0
        sigma  = opts[:sigma].to_f  || 10.0

        rmagick_image(temp_object).vignette(x, y, radius, sigma).to_blob
      end
      
      private
      
      def rmagick_image(temp_object)
        Magick::Image.from_blob(temp_object.data).first
      end

      # Use css-style padding declaration, i.e.
      # 10        (all sides)
      # 10 5      (top/bottom, left/right)
      # 10 5 10   (top, left/right, bottom)
      # 10 5 10 5 (top, right, bottom, left)
      def parse_padding_string(str)
        padding_parts = str.gsub('px','').split(/\s+/).map{|px| px.to_i}
        case padding_parts.size
        when 1
          p = *padding_parts
          [p,p,p,p]
        when 2
          p,q = *padding_parts
          [p,q,p,q]
        when 3
          p,q,r = *padding_parts
          [p,q,r,q]
        when 4
          padding_parts
        else raise ArgumentError, "Couldn't parse padding string '#{str}' - should be a css-style string"
        end
      end

    end

  end
end
