URLs
====

Due to the lazy nature of {Dragonfly::Job Job} objects (see {file:GeneralUsage}), and model accessors which have
similar behaviour (see {file:ActiveModel}), we can get urls for any kind of job:

    app = Dragonfly[:images]

    app.fetch('my_uid').process(:flip).url                    # "/BAhbBlsH..."
    app.generate(:text, 'hello').thumb('500x302').gif.url     # "/BAhbCFsHOgZ..."

Path prefix
-----------
If the app is mounted with a path prefix (such as when using in Rails), then we need to add this prefix
to the urls:

    app.url_path_prefix = '/media'

(or done in a configuration block).

    app.fetch('my_uid').url                               # "/media/BAhbBlsH..."

This is done for you when using {file:Configuration Rails defaults}.

You can override it using

    app.fetch('my_uid').url(:path_prefix => '/images')    # "/images/BAhbBlsH..."

Host
----
You can also set a host for the urls

    app.url_host = 'http://some.host'
    app.fetch('my_uid').url                                  # "http://some.host/BAhb..."

    app.fetch('my_uid').url(:host => 'http://localhost:80')  # "http://localhost:80/BAh..."

Avoiding Denial-of-service attacks
----------------------------------
The url given above, `/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x30`, could easily be modified to
generate all different sizes of thumbnails, just by changing the size, e.g.

`/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x31`,

`/2009/11/29/145804_file.gif?m=resize&o[geometry]=30x32`,

etc.

Therefore the app can protect the url by generating a unique sha from a secret specified by you

    Dragonfly[:images].configure do |c|
      c.protect_from_dos_attacks = true                           # Actually this is true by default
      c.secret = 'You should supply some random secret here'
    end

Then the required urls become something more like

`/2009/12/10/215214_file.gif?m=resize&o[geometry]=30x30&s=aa78e877ad3f6bc9`,

with a sha parameter on the end.
If we try to hack this url to get a different thumbnail,

`/2009/12/10/215214_file.gif?m=resize&o[geometry]=30x31&s=aa78e877ad3f6bc9`,

then we get a 400 (bad parameters) error.
