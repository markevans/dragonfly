require 'dragonfly/hash_with_css_style_keys'

module Dragonfly
  module ImageMagick
    module Generators
      class Text

        FONT_STYLES = {
          'normal'  => 'normal',
          'italic'  => 'italic',
          'oblique' => 'oblique'
        }

        FONT_STRETCHES = {
          'normal'          => 'normal',
          'semi-condensed'  => 'semi-condensed',
          'condensed'       => 'condensed',
          'extra-condensed' => 'extra-condensed',
          'ultra-condensed' => 'ultra-condensed',
          'semi-expanded'   => 'semi-expanded',
          'expanded'        => 'expanded',
          'extra-expanded'  => 'extra-expanded',
          'ultra-expanded'  => 'ultra-expanded'
        }

        FONT_WEIGHTS = {
          'normal'  => 'normal',
          'bold'    => 'bold',
          'bolder'  => 'bolder',
          'lighter' => 'lighter',
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

        def update_url(url_attributes, string, opts={})
          url_attributes.name = "text.#{extract_format(opts)}"
        end

        def call(content, string, opts={})
          opts = HashWithCssStyleKeys[opts]
          args = []
          format = extract_format(opts)
          background = opts['background_color'] || 'none'
          font_size = (opts['font_size'] || 12).to_i
          escaped_string = "\"#{string.gsub(/"/, '\"')}\""

          # Settings
          args.push("-gravity NorthWest")
          args.push("-antialias")
          args.push("-pointsize #{font_size}")
          args.push("-font \"#{opts['font']}\"") if opts['font']
          args.push("-family '#{opts['font_family']}'") if opts['font_family']
          args.push("-fill #{opts['color']}") if opts['color']
          args.push("-stroke #{opts['stroke_color']}") if opts['stroke_color']
          args.push("-style #{FONT_STYLES[opts['font_style']]}") if opts['font_style']
          args.push("-stretch #{FONT_STRETCHES[opts['font_stretch']]}") if opts['font_stretch']
          args.push("-weight #{FONT_WEIGHTS[opts['font_weight']]}") if opts['font_weight']
          args.push("-background #{background}")
          args.push("label:#{escaped_string}")

          # Padding
          pt, pr, pb, pl = parse_padding_string(opts['padding']) if opts['padding']
          padding_top    = (opts['padding_top']    || pt || 0)
          padding_right  = (opts['padding_right']  || pr || 0)
          padding_bottom = (opts['padding_bottom'] || pb || 0)
          padding_left   = (opts['padding_left']   || pl || 0)

          content.generate!(:convert, args.join(' '), format)

          if (padding_top || padding_right || padding_bottom || padding_left)
            dimensions = content.analyse(:image_properties)
            text_width  = dimensions['width']
            text_height = dimensions['height']
            width  = padding_left + text_width  + padding_right
            height = padding_top  + text_height + padding_bottom

            args = args.slice(0, args.length - 2)
            args.push("-size #{width}x#{height}")
            args.push("xc:#{background}")
            args.push("-annotate 0x0+#{padding_left}+#{padding_top} #{escaped_string}")
            content.generate!(:convert, args.join(' '), format)
          end

          content.add_meta('format' => format, 'name' => "text.#{format}")
        end

        private

        def extract_format(opts)
          opts['format'] || 'png'
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
end

