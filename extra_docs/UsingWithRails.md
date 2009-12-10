Using With Rails
================

There are two main ways to use Dragonfly with Rails - as a {Dragonfly::Middleware middleware},
and as a Rails Metal.

Using as Middleware
-------------------
In environment.rb:

    config.gem 'dragonfly-rails', :lib => 'dragonfly/rails/images'
    config.middleware.use 'Dragonfly::MiddlewareWithCache', :images

The gem dragonfly-rails does nothing more than tie together the gem dependencies dragonfly,
rack-cache and rmagick.

The required file 'dragonfly/rails/images.rb' initializes a dragonfly app, configures it to use rmagick processing, encoding, etc.,
and registers the app so that you can use ActiveRecord accessors.

For reference, the contents are as follows:

    require 'dragonfly'

    ### The dragonfly app ###

    app = Dragonfly::App[:images]
    app.configure_with(Dragonfly::RMagickConfiguration)
    app.configure do |c|
      c.log = RAILS_DEFAULT_LOGGER
      c.datastore.configure do |d|
        d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
      end
      c.url_handler.configure do |u|
        u.protect_from_dos_attacks = false
        u.path_prefix = '/media'
      end
    end

    ### Extend active record ###
    ActiveRecord::Base.extend Dragonfly::ActiveRecordExtensions
    ActiveRecord::Base.register_dragonfly_app(:image, app)

The second line configures rails to use a {Dragonfly::MiddlewareWithCache middleware} which uses the named app (named `:images`), and puts
{http://tomayko.com/src/rack-cache/ Rack::Cache} in front of it for performance.
You can pass extra arguments to this line which will go directly to configuring Rack::Cache (see its docs for how to configure it).
The default configuration for Rack::Cache is

    {
      :verbose     => true,
      :metastore   => 'file:/var/cache/rack/meta',
      :entitystore => 'file:/var/cache/rack/body'
    }

To see what you can do with the active record accessors, see {file:ActiveRecord}.

Using as a Rails Metal
----------------------
The easiest way of setting up as a rails metal is using the supplied generator.
(NB I've had a couple of problems with the generator with plural/singular names with early versions of metal in Rails 2.3 -
this should be resolvable by making sure the metal name matches its filename).

    ./script/generate dragonfly_app images
    
The argument 'images' could be anything - it is an arbitrary app name.

This does two things:

1. Creates and configures an app as a rails metal
2. Registers the app for use with ActiveRecord - see {file:ActiveRecord}

For reference, the contents of the metal file is given below. You could do something similar yourself without the generator.

    # Allow the metal piece to run in isolation
    require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
    require 'dragonfly'

    # Configuration of the Dragonfly App
    Dragonfly::App[:images].configure_with(Dragonfly::RMagickConfiguration)
    Dragonfly::App[:images].configure do |c|
      c.log = RAILS_DEFAULT_LOGGER
      c.datastore.configure do |d|
        d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
      end
      c.url_handler.configure do |u|
        u.secret = '29205f3e01648d0966bd5b119cd53347390a9ba9'
        u.path_prefix = '/images'
      end
    end

    # The metal, for running the app
    app = Dragonfly::App[:images]
    Images = Rack::Builder.new do

      # UNCOMMENT ME!!!
      # ... if you want to use super-dooper middleware 'rack-cache'
      # require 'rack/cache'
      # use Rack::Cache,
      #   :verbose     => true,
      #   :metastore   => 'file:/var/cache/rack/meta',
      #   :entitystore => 'file:/var/cache/rack/body'

      run app

    end
