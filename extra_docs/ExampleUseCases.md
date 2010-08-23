Example Use Cases
=================

Image thumbnails in Rails
-------------------------
See {file:UsingWithRails}

Image thumbnails in Rails, hosted on Heroku with S3 storage
-----------------------------------------------------------
The default configuration won't work out of the box for Heroku, because

- Heroku doesn't allow saving files to the filesystem (although it does use tempfiles)
- We won't need {http://tomayko.com/src/rack-cache/ Rack::Cache} on Heroku because it already uses the caching proxy {http://varnish.projects.linpro.no/ Varnish}, which we can make use of

Instead of the normal {Dragonfly::DataStorage::FileDataStore FileDataStore}, we can use the {Dragonfly::DataStorage::S3DataStore S3DataStore}.

Assuming you have an S3 account set up...

Gem dependencies:

    - rmagick (require as 'RMagick')
    - aws-s3 (require as aws/s3)
    - dragonfly

Initializer (e.g. config/initializers/dragonfly.rb):

    require 'dragonfly'
    app = Dragonfly[:images]

    app.configure_with(:rmagick)
    app.configure_with(:rails)
    app.configure_with(:heroku, 'my_bucket_name') if Rails.env.production?

    app.define_macro(ActiveRecord::Base, :image_accessor)

The datastore remains as the {Dragonfly::DataStorage::FileDataStore FileDataStore} for non-production environments.

environment.rb (application.rb in Rails 3):

    config.middleware.insert 0, 'Dragonfly::Middleware', :images, '/media'  # make sure this is the same
                                                                            # as the app's configured prefix

We don't store the S3 access key and secret in the repository, rather we use Heroku's
{http://docs.heroku.com/config-vars config variables} using the command line (we only have to do this once).

From your app's directory:

    heroku config:add S3_KEY=XXXXXXXXX S3_SECRET=XXXXXXXXXX

Obviously replace 'XXXXXXXXX' with your access key and secret.

Now you can benefit from super-fast images served straight from Heroku's cache!

NOTE: HEROKU'S CACHE IS CLEARED EVERY TIME YOU DEPLOY!!!

If this is an issue, you may want to look into using something like a Memcached add-on, or maybe an after-deploy hook for hitting specific Dragonfly urls you want to cache, etc.
It won't be a problem for most sites though.


Text image replacement
----------------------
Configure the dragonfly app to use RMagick if not already done. Then

    url = app.generate(:text, 'Some text here!!!').url

will give you the required url. See {file:Generators} for more info.


Sinatra
-------
You can use {Dragonfly::Job Job}'s `to_response` method like so:

    get '/images/:size.:format' do |size, format|
      app.fetch_file('~/some/image.png').thumb(size).encode(format).to_response
    end

NOTE: uids from the datastore currently have slashes and dots in them so may cause problems when using ':uid' as
a path segment.

or you can mount as a middleware, like in rails:

    Dragonfly[:images].configure_with(:rmagick) do |c|
      c.url_path_prefix = '/media'
    end

    use Dragonfly::Middleware, :images, '/media'

    get '/' do
      # ...

Attachments with no processing or encoding
------------------------------------------
This should just work out of the box - just don't call process or encode methods.
