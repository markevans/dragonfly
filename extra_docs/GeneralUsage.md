General Usage
=============

You can have multiple dragonfly apps, each with their own configuration.
Each app has a name, and is referred to by that name.

    Dragonfly[:images]    # ===> Creates an app called 'images'
    Dragonfly[:images]    # ===> Refers to the already created app 'images'

    app = Dragonfly[:images]

Getting/generating content
--------------------------
A number of methods can be used to get content:

    app.fetch('some_uid')                   # Fetch from datastore (default filesystem)

    app.fetch_file('~/path/to/file.png')    # Fetch from a local file

    app.fetch_url('somewhere.com/img.png')  # Fetch from a url (will work with http, https)

    app.generate(:plasma, 400, 300)         # Generates using a method from the configured
                                            # generator (in this case a plasma image)

    app.create("CONTENT")                   # Can pass in a String, Pathname, File or Tempfile

These all return {Dragonfly::Job Job} objects. These objects are lazy - they don't do any fetching/generating until
some other method is called on them.

Using the content
-----------------
Once we have a {Dragonfly::Job Job} object:

    image = app.fetch('some_uid')

We can get the data a number of ways...

    image.data                           # => "\377???JFIF\000\..."
    image.to_file('out.png')             # writes to file 'out.png' and returns a readable file object
    image.tempfile                       # => #<File:/var/folders/st/strHv74sH044JPabSiODz... a closed Tempfile object
    image.file                           # => #<File:/var/folders/st/strHv74sH044JPabSiODz... a readable (open) File object
    image.file do |f|                    # Yields an open file object, returns the return value of
      data = f.read(256)                 #  the block, and closes the file object
    end
    image.path                           # => '/var/folders/st/strHv74sH044JPabSiODz...' i.e. the path of the tempfile
    image.size                           # => 134507 (size in bytes)

We can get its url...

    image.url                            # => "/media/BAhbBlsHOgZmIg9hc..."
                                         # this won't work if we've used create to get the content

We can analyse it (see {file:Analysers} for more info) ...

    image.width                          # => 280

We can process it (see {file:Processing} for more info) ...

    new_image = image.process(:thumb, '40x30')    # returns another 'Job' object

We can encode it (see {file:Encoding} for more info) ...

    new_image = image.encode(:gif)                # returns another 'Job' object

Chaining
--------
Because the methods `fetch`, `fetch_file`, `fetch_url`, `generate`, `create`, `process` and `encode`
all return {Dragonfly::Job Job} objects, we can chain them as much as we want...

    image = app.fetch('some_uid').process(:greyscale).process(:thumb, '40x20#').encode(:gif)

... and because they're lazy, we don't actually do any processing/encoding until either `apply` is called

    image.apply              # actually 'does' the processing and returns self

... or a method is called like `data`, `to_file`, etc.

This means we can cheaply generate urls for processed data without doing any fetching or processing:

    url = app.fetch('some_uid').process(:thumb, '40x20#').encode(:gif).url

and then visit that url in a browser to get the actual processed image.

Shortcuts
---------
Commonly used processing/encoding steps can be shortened, so instead of

    app.fetch('some_uid').process(:greyscale).process(:thumb, '40x20#').encode(:jpg)

we could use something like

    app.fetch('some_uid').grey('40x20#')

This does exactly the same, returning a {Dragonfly::Job Job} object.

To define this shortcut:

    app.configure do |c|
      c.job :grey do |size|
        process :greyscale
        process :thumb, size
        encode :jpg
      end
      # ...
    end
