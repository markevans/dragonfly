module Dragonfly
  module Config

    module RMagickText

      def self.apply_configuration(app)
        app.configure do |c|
          c.datastore = DataStorage::TransparentDataStore.new
          c.register_analyser(Analysis::FileCommandAnalyser)
          c.register_processor(Processing::RMagickTextProcessor)
          c.register_encoder(Encoding::RMagickEncoder)
          c.parameters.add_shortcut :text, Hash do |_, options|
            {
              :processing_method => :text,
              :processing_options => options,
              :format => :png
            }
          end
        end

      end

    end
  end
end
