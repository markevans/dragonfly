module Dragonfly
  module Config

    module Rails

      def self.apply_configuration(app)
        app.configure do |c|
          c.log = ::Rails.logger
          c.datastore.root_path = "#{::Rails.root}/public/system/dragonfly/#{::Rails.env}"
          c.path_prefix = '/media'
        end
      end

    end
  end
end
