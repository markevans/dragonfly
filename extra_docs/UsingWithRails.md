Using With Rails
================

Dragonfly works with both Rails 2.3 and Rails 3.

The main way to use Dragonfly with Rails is as a {Dragonfly::Middleware middleware}.

1. The initializer
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
If you want to set up and configure the Dragonfly app yourself, then you can put something like the code below in an initializer and
modify accordingly:

    require 'dragonfly'

    # Set up and configure the dragonfly app
    app = Dragonfly::App[:images]
    app.configure_with(Dragonfly::RMagickConfiguration)
    app.configure do |c|
      c.log = Rails.logger
      c.datastore.configure do |d|
        d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
      end
      c.url_handler.configure do |u|
        u.secret = 'insert some secret here to protect from DOS attacks!'
        u.path_prefix = '/media'
      end
    end

    # Extend ActiveRecord
    # This allows you to use e.g.
    #   image_accessor :my_attribute
    # in your models.
    ActiveRecord::Base.extend Dragonfly::ActiveRecordExtensions
    ActiveRecord::Base.register_dragonfly_app(:image, Dragonfly::App[:images])

    ### Insert the middleware ###
    # Where the middleware is depends on the version of Rails
    middleware = Rails.respond_to?(:application) ? Rails.application.middleware : ActionController::Dispatcher.middleware
    middleware.insert_after Rack::Lock, Dragonfly::Middleware, :images

    # # UNCOMMENT THIS IF YOU WANT TO CACHE REQUESTS WITH Rack::Cache
    # require 'rack/cache'
    # middleware.insert_before Dragonfly::Middleware, Rack::Cache, {
    #   :verbose     => true,
    #   :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
    #   :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
    # }

If you can't be bothered to copy and paste, then there's actually a generator for Rails 2.3 (not Rails 3 yet) that will do something like the above for you:

    ./script/generate dragonfly_app images

2. Gem dependencies
-------------------

Tell Rails about the gem dependencies in the usual way:

For Rails 2.3 add this to config/environment.rb:

    config.gem 'rmagick',    :lib => 'RMagick'      # only if used
    config.gem 'rack-cache', :lib => 'rack/cache'   # only if used
    config.gem 'dragonfly'

For Rails 3 add it to the Gemfile, e.g.:

    gem 'rmagick',    :require => 'RMagick'         # only if used
    gem 'rack-cache', :require => 'rack/cache'      # only if used
    gem 'dragonfly'

You only need the lines above for {http://tomayko.com/src/rack-cache/ rack-cache} and
{http://rmagick.rubyforge.org/ rmagick} if you've used the file 'dragonfly/rails/images', or manually used them yourself.

3. Use it!
----------

Now that you have a parasitic Dragonfly app living inside your Rails app, you can upload media to your models, display/play around with them, etc.

To see what you can do with the active record accessors, see {file:ActiveRecord}.

For more info about general Dragonfly setup, including avoiding denial-of-service attacks, see {file:GettingStarted}.
