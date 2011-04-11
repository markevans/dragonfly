module Dragonfly
  module Config

    module Rails

      def self.apply_configuration(app)
        app.configure do |c|
          c.log = ::Rails.logger
          if c.datastore.is_a?(DataStorage::FileDataStore)
            c.datastore.root_path = ::Rails.root.join('public/system/dragonfly', ::Rails.env).to_s
            c.datastore.server_root = ::Rails.root.join('public').to_s
          end
          c.url_format = '/media/:job/:basename.:format'
          c.analyser.register(Analysis::FileCommandAnalyser)
        end
      end

    end
  end
end
