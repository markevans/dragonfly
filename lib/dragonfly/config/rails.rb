module Dragonfly
  module Config

    module Rails

      def self.apply_configuration(app)
        app.configure do |c|
          c.log = ::Rails.logger
          c.datastore.root_path = "#{::Rails.root}/public/system/dragonfly/#{::Rails.env}" if c.datastore.is_a?(DataStorage::FileDataStore)
          c.url_path_prefix = '/media'
          c.analyser.register(Analysis::FileCommandAnalyser)
        end
      end

    end
  end
end
