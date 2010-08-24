Using With Rails 2.3
====================

Setting up the quick way
------------------------
config/initializers/dragonfly.rb:

    require 'dragonfly/rails/images'

Setting up the more explicit way
--------------------------------
You can do the above explicitly.

config/initializers/dragonfly.rb:

    require 'dragonfly'

    app = Dragonfly[:images]
    app.configure_with(:rmagick)
    app.configure_with(:rails)

    app.define_macro(ActiveRecord::Base, :image_accessor)

environment.rb:

    config.gem 'dragonfly', '~>0.7.0'
    config.gem 'rmagick', :lib => 'RMagick'
    config.gem 'rack-cache', :lib => 'rack/cache'

    config.middleware.insert 0, 'Dragonfly::Middleware', :images, '/media'
    config.middleware.insert 0, 'Rack::Cache', {
      :verbose     => true,
      :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
      :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
    }

Use it!
-------

To see what you can do with the model accessors, see {file:ActiveModel}.
