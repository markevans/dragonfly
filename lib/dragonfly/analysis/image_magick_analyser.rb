module Dragonfly
  module Analysis
    class ImageMagickAnalyser

      include ImageMagickUtils
      include Configurable

      def width(temp_object)
        quiet_identify(temp_object)[:width]
      end

      def height(temp_object)
        quiet_identify(temp_object)[:height]
      end

      def aspect_ratio(temp_object)
        attrs = quiet_identify(temp_object)
        attrs[:width].to_f / attrs[:height]
      end

      def portrait?(temp_object)
        attrs = quiet_identify(temp_object)
        attrs[:width] <= attrs[:height]
      end

      def landscape?(temp_object)
        attrs = quiet_identify(temp_object)
        attrs[:width] >= attrs[:height]
      end

      def depth(temp_object)
        quiet_identify(temp_object)[:depth]
      end

      def number_of_colours(temp_object)
        details = quiet_identify(temp_object, '-verbose -unique')
        details.match(/Colors: ([0-9]+)/)[1].to_i
      end
      alias number_of_colors number_of_colours

      def format(temp_object)
        quiet_identify(temp_object)[:format]
      end

      def quiet_identify(temp_object, args='')
        original_stderr = $stderr.dup

        begin
          tempfile = Tempfile.new('stderr')
          $stderr.reopen(tempfile)
          identify(temp_object, args)
        rescue ShellCommandFailed
          throw :unable_to_handle
        ensure
          $stderr.reopen(original_stderr)
        end
      end

    end
  end
end
