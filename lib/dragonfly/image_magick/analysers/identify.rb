module Dragonfly
  module ImageMagick
    module Analysers
      class Identify < Base

        def call(temp_object, args="")
          command_line.identify(temp_object, args)
        end

      end
    end
  end
end
