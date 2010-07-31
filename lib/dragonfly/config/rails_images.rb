module Dragonfly
  module Config
    
    module RailsImages
    
      def self.apply_configuration(app)
        app.configure_with(RMagick)
        app.configure_with(RailsDefaults)
      end

    end
  end
end
