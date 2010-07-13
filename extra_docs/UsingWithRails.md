Using With Rails
================

Dragonfly works with both Rails 2.3 and Rails 3.

The main way to use Dragonfly with Rails is as a {Dragonfly::Middleware middleware}.

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

    app = Dragonfly::App[:images]
    app.configure_with(Dragonfly::Config::RailsImages)
    
    # Define the method 'image_accessor' in ActiveRecord models
    Dragonfly.active_record_macro(:image, app)

environment.rb (application.rb in Rails 3):

    config.middleware.insert_after 'Rack::Lock', 'Dragonfly::Middleware', :images
    config.middleware.insert_before 'Dragonfly::Middleware', 'Rack::Cache', {
      :verbose     => true,
      :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
      :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
    }

2. Gem dependencies
-------------------

Tell Rails about the gem dependencies in the usual way:

For Rails 2.3 add this to config/environment.rb:

    config.gem 'rmagick',    :lib => 'RMagick'      # only if used
    config.gem 'rack-cache', :lib => 'rack/cache'   # only if used
    config.gem 'dragonfly',  :version => '~>0.6.2'

For Rails 3 add it to the Gemfile, e.g.:

    gem 'rmagick',    :require => 'RMagick'         # only if used
    gem 'rack-cache', :require => 'rack/cache'      # only if used
    gem 'dragonfly', '~>0.6.2'

You only need the lines above for {http://tomayko.com/src/rack-cache/ rack-cache} and
{http://rmagick.rubyforge.org/ rmagick} if you've used the file 'dragonfly/rails/images', or manually used them yourself.

3. Use it!
----------

Now that you have a parasitic Dragonfly app living inside your Rails app, you can upload media to your models, display/play around with them, etc.

To see what you can do with the active record accessors, see {file:ActiveRecord}.

For more info about general Dragonfly setup, including avoiding denial-of-service attacks, see {file:GettingStarted}.

Extra Config
------------
There are one or two config options you may commonly want to tweak.
In this case, add something like the following to your initializer:

    Dragonfly::App[:images].configure do |c|
      c.url_handler.path_prefix = '/attachments'   # configures where the Dragonfly app is served from - default '/media'
      c.url_handler.secret = 'PUT A SECRET HERE!!' # for protecting from Denial-Of-Service attacks
    end
