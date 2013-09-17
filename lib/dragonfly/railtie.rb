require 'dragonfly/cookie_monster'

if defined?(Rails::Railtie)
  module Dragonfly
    class Railtie < ::Rails::Railtie
      initializer "dragonfly.railtie.initializer" do |app|
        app.middleware.insert 3, Dragonfly::CookieMonster
      end
    end
  end
end

