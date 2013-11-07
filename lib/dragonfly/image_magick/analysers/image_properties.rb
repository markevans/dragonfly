module Dragonfly
  module ImageMagick
    module Analysers
      class ImageProperties

        def call(content)
          identify_command = content.env[:identify_command] || 'identify'
          details = content.shell_eval do |path|
            "#{identify_command} -ping -format '%m %w %h' #{path}"
          end
          format, width, height = details.split
          {
            'format' => format.downcase,
            'width' => width.to_i,
            'height' => height.to_i
          }
        end

      end
    end
  end
end

