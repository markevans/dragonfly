Heroku
======

The default configuration won't work out of the box for Heroku, because

- Heroku doesn't allow saving files to the filesystem (although it does use tempfiles)
- If on Heroku {http://devcenter.heroku.com/articles/stack Aspen/Bamboo stacks}, we won't need {http://tomayko.com/src/rack-cache/ Rack::Cache},
because it already uses the caching proxy {http://varnish.projects.linpro.no/ Varnish}, which we can make use of.
We will still need it on {http://devcenter.heroku.com/articles/cedar Heroku Cedar}, however, as it doesn't include Varnish.

Instead of the normal {file:DataStorage#File\_datastore FileDataStore}, we can use the {file:DataStorage#S3\_datastore S3DataStore}.

Assuming you have an S3 account set up...

Gem dependencies:

    - fog
    - dragonfly

Initializer (e.g. config/initializers/dragonfly.rb in Rails):

    require 'dragonfly'
    app = Dragonfly[:images]

    app.configure_with(:imagemagick)
    app.configure_with(:rails)
    if Rails.env.production?
      app.configure do |c|
        c.datastore = Dragonfly::DataStorage::S3DataStore.new(
          :bucket_name => 'my-bucket-name',
          :access_key_id => ENV['S3_KEY'],
          :secret_access_key => ENV['S3_SECRET']
        )
      end
    end

    app.define_macro(ActiveRecord::Base, :image_accessor)

The datastore remains as the {Dragonfly::DataStorage::FileDataStore FileDataStore} for non-production environments.

application.rb if using with Rails:

    config.middleware.insert 1, 'Dragonfly::Middleware', :images

We don't store the S3 access key and secret in the repository, rather we use Heroku's
{http://docs.heroku.com/config-vars config variables} using the command line (we only have to do this once).

From your app's directory:

    heroku config:add S3_KEY=XXXXXXXXX S3_SECRET=XXXXXXXXXX

Replace 'XXXXXXXXX' with your access key and secret.

**NOTE**: HEROKU'S VARNISH CACHE IS CLEARED EVERY TIME YOU DEPLOY!!! (DOESN'T APPLY TO CEDAR STACK)

If this is an issue, you may want to look into storing thumbnails on S3 (see {file:ServingRemotely}), or maybe generating thumbnails _on upload_ (see {file:Models#Up-front_thumbnailing}), or maybe an after-deploy hook for hitting specific Dragonfly urls you want to cache, etc.
It won't be a problem for most sites though.
