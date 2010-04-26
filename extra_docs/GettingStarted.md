Getting Started
===============

Below is a general guide for setting up and using Dragonfly.

For setting up with Ruby on Rails, see {file:UsingWithRails UsingWithRails}.

For more info about using Rack applications, see the docs at {http://rack.rubyforge.org/}

Running as a Standalone Rack Application
----------------------------------------

Basic usage of a dragonfly app involves storing data (e.g. images),
then serving that data, either in its original form, processed, encoded or both.

A basic rackup file `config.ru`:

    require 'rubygems'
    require 'dragonfly'

    Dragonfly::App[:my_app_name].configure do |c|
      # ...
      c.some_attribute = 'blah'
      # ...
    end

    run Dragonfly:App[:my_app_name]

As you can see, this involves instantiating an app, configuring it (how data is stored,
processing, encoding, etc.), then running it.

You can have multiple dragonfly apps, each with their own configuration.
Each app has a name, and is referred to by that name.

    Dragonfly::App[:images]    # ===> Creates an app called 'images'
    Dragonfly::App[:images]    # ===> Refers to the already created app 'images'

Example: Using to serve resized images
--------------------------------------

`config.ru`:

    require 'rubygems'
    require 'dragonfly'
    require 'rack/cache'

    app = Dragonfly::App[:images]
    app.configure_with(Dragonfly::Config::RMagickImages)

    use Rack::Cache,
      :verbose     => true,
      :metastore   => 'file:/var/cache/rack/meta',
      :entitystore => 'file:/var/cache/rack/body'

    run app

This configures the app to use the RMagick {Dragonfly::Processing::RMagickProcessor processor},
{Dragonfly::Encoding::RMagickEncoder encoder} and {Dragonfly::Analysis::RMagickAnalyser analyser}.
By default the {Dragonfly::DataStorage::FileDataStore file data store} is used.

Elsewhere in our code:

    app = Dragonfly::App[:images]
    
    # Store
    uid = app.store(File.new('path/to/image.png'))   # ===> returns a unique uid for that image, "2009/11/29/145804_file"
    
    # Get the url for a thumbnail
    url = app.url_for(uid, '30x30', :gif)            # ===> "/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x30"

Now when we visit the url `/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x30` in the browser, we get the resized
image!

Caching
-------
Processing and encoding can be an expensive operation. The first time we visit the url,
the image is processed, and there might be a short delay and getting the response.

However, dragonfly apps send `Cache-Control` and `ETag` headers in the response, so we can easily put a caching
proxy like {http://varnish.projects.linpro.no Varnish}, {http://www.squid-cache.org Squid},
{http://tomayko.com/src/rack-cache/ Rack::Cache}, etc. in front of the app.

In the example above, we've put the middleware {http://tomayko.com/src/rack-cache/ Rack::Cache} in front of the app.
So although the first time we access the url the content is processed, every time after that it is received from the
cache, and is served super quick!

Avoiding Denial-of-service attacks
----------------------------------
The url given above, `/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x30`, could easily be modified to
generate all different sizes of thumbnails, just by changing the size, e.g.

`/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x31`,

`/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x32`,

etc.

Therefore the app can protect the url by generating a unique sha from a secret specified by you

    Dragonfly::App[:images].url_handler.configure do |c|
      c.protect_from_dos_attacks = true                           # Actually this is true by default
      c.secret = 'You should supply some random secret here'
    end

Then the required urls become something more like

`/2009/12/10/215214_file.gif?m=resize&o[geometry]=30x30&s=aa78e877ad3f6bc9`,

with a sha parameter on the end.
If we try to hack this url to get a different thumbnail,

`/2009/12/10/215214_file.gif?m=resize&o[geometry]=30x31&s=aa78e877ad3f6bc9`,

then we get a 400 (bad parameters) error.
