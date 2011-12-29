require 'dragonfly'
require 'rails'

module Dragonfly
  class Railtie < ::Rails::Railtie
    initializer "dragonfly.railtie.initializer" do |app|
      app.middleware.insert_before 'ActionDispatch::Cookies', Dragonfly::CookieMonster
    end
  end
end
