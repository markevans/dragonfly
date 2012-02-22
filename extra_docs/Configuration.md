Configuration
=============

Given a Dragonfly app

    app = Dragonfly[:app_name]

Configuration can either be done using a block...

    app.configure do |c|
      c.url_format = '/media/:job'
      # ...
    end

...or directly...

    app.url_format = '/media/:job'

The defaults should be fairly sensible, but you can tweak a number of things if you wish.
Here is an example of an app with all attributes configured:

    app.configure do |c|
      c.datastore = SomeCustomDataStore.new :egg => 'head'  # defaults to FileDataStore

      c.cache_duration = 3600*24*365*2                      # defaults to 1 year # (1 year)
      c.fallback_mime_type = 'something/mental'             # defaults to application/octet-stream
      c.log = Logger.new($stdout)                           # defaults to Logger.new('/var/tmp/dragonfly.log')
      c.trust_file_extensions = false                       # defaults to true

      c.url_format = '/images/:job/:basename.:format'       # defaults to '/:job/:basename.:format'
      c.url_host = 'http://some.domain.com:4000'            # defaults to nil

      c.content_filename = proc{|job, request|              # defaults to the original name, with modified ext if encoded
        "file.#{job.ext}"
      }
      c.content_disposition = :attachment                   # defaults to nil (use the browser default)

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
      
      c.define_url do |app, job, opts|                      # allows overriding urls - defaults to
        if job.step_types == [:fetch]                       #   app.server.url_for(job, opts)
          app.datastore.url_for(job.uid)
        else
          app.server.url_for(job, opts)
        end
      end
      
      c.server.before_serve do |job, env|                   # allows you to do something before content is served
        # do something
      end
      
      c.response_headers['X-Something'] = 'Custom header'   # You can set custom response headers
      c.response_headers['summink'] = proc{|job, request|   # either directly or via a callback
        job.image? ? 'image yo' : 'not an image'
      }
      
      # When using ImageMagick only...
      c.convert_command = "/opt/local/bin/convert"          # defaults to "convert"
      c.identify_command = "/opt/local/bin/identify"        # defaults to "identify"
      c.log_commands = true                                 # defaults to false
    end

Where is configuration done?
----------------------------
In Rails, it should be done in an initializer, e.g. 'config/initializers/dragonfly.rb'.
Otherwise it should be done anywhere where general setup is done, early on.

Reflecting on configuration
---------------------------
There are a few methods you can call on the `app` to see what processors etc. are registered: `processor_methods`, `generator_methods`, `analyser_methods` and `job_methods`.

Saved configurations
====================
Saved configurations are useful if you often configure the app the same way.
There are a number that are provided with Dragonfly:

ImageMagick
-----------

    app.configure_with(:imagemagick)

The {Dragonfly::ImageMagick::Config ImageMagick configuration} registers the app with the {Dragonfly::ImageMagick::Analyser ImageMagick Analyser}, {Dragonfly::ImageMagick::Processor ImageMagick Processor},
{Dragonfly::ImageMagick::Encoder ImageMagick Encoder} and {Dragonfly::ImageMagick::Generator ImageMagick Generator}, and a number of job shortcuts.

The file 'dragonfly/rails/images' does this for you.

The processor, analyser, encoder and generator pass data around using tempfiles.

Rails
-----

    app.configure_with(:rails)

The {Dragonfly::Config::Rails Rails configuration} points the log to the Rails logger, configures the file data store root path, sets the url path prefix to '/media', and
registers the {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} for helping with mime_type validations.

The file 'dragonfly/rails/images' does this for you.

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

If you wish to be able to use a symbol to represent your configuration (e.g. for a plugin, etc.) you can register it
globally as a one-off:

    Dragonfly::App.register_configuration(:myconfig){ My::Saved::Configuration }

Then from then on you can configure Dragonfly apps using

    app.configure_with(:myconfig, :any_other => :args)
