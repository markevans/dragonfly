Rack
====
For more info about using Rack applications, see the docs at {http://rack.rubyforge.org/}

Basic usage involves storing data (e.g. images),
then serving it in some form.

A basic rackup file `config.ru`:

    require 'rubygems'
    require 'dragonfly'

    Dragonfly[:my_app_name].configure do |c|
      # ... configuration here
    end

    run Dragonfly:App[:my_app_name]

See {file:Configuration} for more details.

The basic flow is instantiate an app -> configure it -> run it.

Example: Using to serve resized images
--------------------------------------

`config.ru`:

    require 'rubygems'
    require 'dragonfly'

    app = Dragonfly[:images].configure_with(:imagemagick)

    run app

This enables the app to use all the ImageMagick goodies provided by Dragonfly (see {file:Configuration}).
By default the {Dragonfly::DataStorage::FileDataStore file data store} is used.

In the console:

    app = Dragonfly[:images]

    # Store
    uid = app.store(File.new('path/to/image.png'))      # ===> unique uid

    # Get the url for a thumbnail
    url = app.fetch(uid).thumb('400x300').url           # ===> "/media/BAhbBlsHOgZmIg9hc..."

Now when we visit the url `/media/BAhbBlsHOgZmIg9hc...` in the browser, we get a resized image!

Mounting in Rack
----------------
See {file:URLs}
