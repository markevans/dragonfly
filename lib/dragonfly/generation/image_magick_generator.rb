module Dragonfly
  module Generation
    class ImageMagickGenerator

      FONT_STYLES = {
        'normal' => 'normal',
        'italic' => 'italic',
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

      include ImageMagickUtils
      include Configurable

      def plasma(width, height, format='png')
        tempfile = new_tempfile(format)
        run "#{convert_command} -size #{width}x#{height} plasma:fractal #{tempfile.path}"
        [
          tempfile,
          {:format => format.to_sym, :name => "plasma.#{format}"}
        ]
      end

    end
  end
end
