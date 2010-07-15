module Dragonfly
  module Config

    module RMagickText

      def self.apply_configuration(app)
        app.configure do |c|
          c.register_analyser(Analysis::FileCommandAnalyser)
          c.register_generator(Generation::RMagickGenerator)
          c.register_encoder(Encoding::RMagickEncoder)
        end

      end

    end
  end
end
