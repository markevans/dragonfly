Using With Rails
================

Dragonfly works with both Rails 2.3 and Rails 3.

1. Setting up
------------------

The quick way
-------------
There is a ready-made file which sets up Dragonfly for image processing for your rails app.
If image resizing, etc. is all you want to do, then put this in an initializer, e.g config/initializers/dragonfly.rb:

    require 'dragonfly/rails/images'

This file initializes a dragonfly app, configures it to use rmagick processing, encoding, etc.,
registers the app so that you can use ActiveRecord accessors, and inserts it into the Rails middleware stack.

The more explicit way
---------------------
You can do the above explicitly.

config/initializers/dragonfly.rb:

    require 'dragonfly'

    app = Dragonfly[:images]
    app.configure_with(:rmagick)
    app.configure_with(:rails)
    
    Dragonfly.define_macro(ActiveRecord::Base, :image_accessor)

environment.rb (application.rb in Rails 3):

    config.middleware.insert 0, 'Dragonfly::Middleware', :images, '/media'
    config.middleware.insert 0, 'Rack::Cache', {
      :verbose     => true,
      :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
      :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
    }

2. Gem dependencies
-------------------

  - dragonfly
  - rmagick (require as 'RMagick') if used
  - rack-cache (require as 'rack/cache') if used

3. Use it!
----------

To see what you can do with the model accessors, see {file:ActiveModel}.

Mounting in Rails 3
-------------------
In Rails 3, instead of mounting as a middleware, you could skip that bit and mount directly in the routes.rb file:

    match '/media/:dragonfly', :to => Dragonfly[:images]

Make sure the the path prefix matches the Dragonfly app's configured path_prefix (which is /media by default for Rails).
