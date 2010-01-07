Using With Rails
================

The main way to use Dragonfly with Rails is as a {Dragonfly::Middleware middleware}.

The quick way
-------------
In environment.rb:

    config.gem 'rmagick',    :lib => 'RMagick'
    config.gem 'rack-cache', :lib => 'rack/cache'
    config.gem 'dragonfly',  :lib => 'dragonfly/rails/images', :source => 'http://gemcutter.org'

The required file 'dragonfly/rails/images.rb' initializes a dragonfly app, configures it to use rmagick processing, encoding, etc.,
registers the app so that you can use ActiveRecord accessors, and inserts it into the Rails middleware stack.

Because in this case it's configured to use {http://tomayko.com/src/rack-cache/ rack-cache} and {http://rmagick.rubyforge.org/ rmagick},
you should include the first two lines above.

To see what you can do with the active record accessors, see {file:ActiveRecord}.

The more explicit way - using an initializer
--------------------------------------------
If you want more control over the configuration, you can do what the file 'dragonfly/rails/images' does yourself,
in an initializer.

In that case in environment.rb we only need:

    config.gem 'rmagick',    :lib => 'RMagick'                 # if used
    config.gem 'rack-cache', :lib => 'rack/cache'              # if used
    config.gem 'dragonfly',  :source => 'http://gemcutter.org'

The easiest way to create the initializer is using the supplied generator
(which will be visible if you have the dragonfly gem installed).

    ./script/generate dragonfly_app images
    
The argument 'images' could be anything - it is an arbitrary app name.

This creates an initializer 'dragonfly_images' which does the following:

1. Creates and configures a dragonfly app
2. Registers the app for use with ActiveRecord - see {file:ActiveRecord}
3. Inserts the app into the Rails middleware stack

For reference, the contents of an example initializer are shown below.
You could just copy and paste this yourself into an initializer if you prefer,
but make sure to change the 'secret' configuration option, so as to protect your app from Denial-of-Service attacks (see {file:GettingStarted}).

    require 'dragonfly'

    # Configuration
    app = Dragonfly::App[:images]
    app.configure_with(Dragonfly::RMagickConfiguration)
    app.configure do |c|
      c.log = RAILS_DEFAULT_LOGGER
      c.datastore.configure do |d|
        d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
      end
      c.url_handler.configure do |u|
        u.secret = 'fed49e269eebed54cc85b28a6c51cba6a543e7b5'
        u.path_prefix = '/media'
      end
    end

    # Extend ActiveRecord
    # This allows you to use e.g.
    #   image_accessor :my_attribute
    # in your models.
    ActiveRecord::Base.extend Dragonfly::ActiveRecordExtensions
    ActiveRecord::Base.register_dragonfly_app(:image, Dragonfly::App[:images])

    # Add the Dragonfly App to the middleware stack
    ActionController::Dispatcher.middleware.insert_after ActionController::Failsafe, Dragonfly::Middleware, :images

    # # UNCOMMENT THIS IF YOU WANT TO CACHE REQUESTS WITH Rack::Cache, and add the line
    # #   config.gem 'rack-cache', :lib => 'rack/cache'
    # # to environment.rb
    # require 'rack/cache'
    # ActionController::Dispatcher.middleware.insert_before Dragonfly::Middleware, Rack::Cache, {
    #   :verbose     => true,
    #   :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
    #   :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
    # }
