module Dragonfly
  module Config
    
    module RailsDefaults
    
      def self.apply_configuration(app)
        app.configure do |c|
          c.log = ::Rails.logger
          c.datastore.root_path = "#{::Rails.root}/public/system/dragonfly/#{::Rails.env}"
          c.url_handler.configure do |u|
            u.path_prefix = '/media'
          end
        end
      end

    end
  end
end
