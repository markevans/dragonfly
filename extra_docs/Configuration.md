Configuration
=============

Given a Dragonfly app

    app = Dragonfly[:app_name]

Configuration can either be done like so...

    app.configure do |c|
      c.url_path_prefix = '/media'
      # ...
    end

...or directly like so...

    app.url_path_prefix = '/media'

The defaults should be fairly sensible, but you can tweak a number of things if you wish.
Here is an example of an app with all attributes configured:

    app.configure do |c|
      c.datastore = SomeCustomDataStore.new :egg => 'head'  # defaults to FileDataStore

      c.cache_duration = 3600*24*365*2                      # defaults to 1 year # (1 year)
      c.fallback_mime_type = 'something/mental'             # defaults to application/octet-stream
      c.log = Logger.new($stdout)                           # defaults to Logger.new('/var/tmp/dragonfly.log')
      c.infer_mime_type_from_file_ext = false               # defaults to true

      c.url_path_prefix = '/images'                         # defaults to nil
      c.url_host = 'http://some.domain.com:4000'            # defaults to nil

      c.protect_from_dos_attacks = true                     # defaults to false - adds a SHA parameter on the end of urls
      c.secret = 'This is my secret yeh!!'                  # should set this if concerned about DOS attacks

      c.analyser.register(MyAnalyser)                       # See 'Analysers' for more details
      c.processor.register(MyProcessor, :type => :fig)      # See 'Processing' for more details
      c.encoder.register(MyEncoder) do |e|                  # See 'Encoding' for more details
        e.some_value = 'geg'
      end
      c.generator.register(MyGenerator)                     # See 'Generators' for more details

      c.register_mime_type(:egg, 'fried/egg')               # See 'MimeTypes' for more details

      c.job :black_and_white do |size|                      # Job shortcut - lets you do image.black_and_white('30x30')
        process :greyscale
        process :thumb, size
        encode  :gif
      end
    end

Where is configuration done?
----------------------------
In Rails, it should be done in an initializer, e.g. 'config/initializers/dragonfly.rb'.
Otherwise it should be done anywhere where general setup is done, early on.

Saved configurations
====================
Saved configurations are useful if you often configure the app the same way.
There are a number that are provided with Dragonfly:

RMagick
-------

    app.configure_with(:rmagick)

The {Dragonfly::Config::RMagick RMagick configuration} registers the app with the {Dragonfly::Analysis::RMagickAnalyser RMagickAnalyser}, {Dragonfly::Processing::RMagickProcessor RMagickProcessor},
{Dragonfly::Encoding::RMagickEncoder RMagickEncoder} and {Dragonfly::Generation::RMagickGenerator RMagickGenerator}, and adds the 'job shortcuts'
`thumb`, `jpg`, `png` and `gif`.

The file 'dragonfly/rails/images' does this for you.

By default the processor, analyser, encoder and generator pass data around using tempfiles.
You can make it pass data around using in-memory strings using

    app.configure_with(:rmagick, :use_filesystem => false)

Rails
-----

    app.configure_with(:rails)

The {Dragonfly::Config::Rails Rails configuration} points the log to the Rails logger, configures the file data store root path, sets the url_path_prefix to /media, and
registers the {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} for helping with mime_type validations.

The file 'dragonfly/rails/images' does this for you.

Heroku
------

    app.configure_with(:heroku, 's3_bucket_name')

The {Dragonfly::Config::Heroku Heroku configuration} configures it to use the {Dragonfly::DataStorage::S3DataStore}, using Heroku's config attributes.
See {file:Heroku} for more info.

Custom Saved Configuration
--------------------------
You can create your own saved configuration with any object that responds to 'apply_configuration':

    module MyConfiguration

      def self.apply_configuration(app, *args)
        app.configure do |c|
          c.url_path_prefix = '/hello/beans'
          c.processor.register(MyProcessor)
          # ...
        end
      end

    end

Then to configure:

    app.configure_with(MyConfiguration, :any_other => :args)     # other args get passed through to apply_configuration

You can also carry on configuring by passing a block

    app.configure_with(MyConfiguration) do |c|
      c.any_extra = :config_here
      # ...
    end
