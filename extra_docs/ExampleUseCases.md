Example Use Cases
=================

This document is concerned with different Dragonfly configurations, for various use cases.

In a Rails app the configuration would generally be done in an initializer.

In other Rack-based apps it could be config.ru, or anywhere where the application is generally set up.


Image thumbnails in Rails, hosted on Heroku with S3 storage
-----------------------------------------------------------
{http://heroku.com Heroku} is a commonly used platform for hosting Rack-based websites.
The following assumes your site is set up for deployment onto Heroku.

As explained in {file:UsingWithRails}, we can use a generator to create an initializer for setting up Dragonfly.

    ./script/generate dragonfly_app images

The default configuration won't work out of the box for Heroku, because

- Heroku doesn't allow saving files to the filesystem (although it does use tempfiles)
- We won't need {http://tomayko.com/src/rack-cache/ Rack::Cache} on Heroku because it already uses the caching proxy {http://varnish.projects.linpro.no/ Varnish}, which we can make use of

Instead of the normal {Dragonfly::DataStorage::FileDataStore FileDataStore}, we can use the {Dragonfly::DataStorage::S3DataStore S3DataStore}.
Amazon's {http://aws.amazon.com/s3 S3} is a commonly used platform for storing data.

The following assumes you have an S3 account set up, and know your provided 'access key' and 'secret'.

Assuming we don't bother with any caching for development/testing environments, our environment.rb then has:

    config.gem 'rmagick', :lib => 'RMagick'
    config.gem 'dragonfly', :source => "http://www.gemcutter.org"

(these are ignored by Heroku but you might want them locally)

The gems file for Heroku, `.gems`, has

    dragonfly

(rmagick not needed because it is already installed)

Then in our configuration initializer, we replace

    c.datastore.configure do |d|
      d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
    end

with

    # Use S3 for production
    if Rails.env == 'production'
      c.datastore = Dragonfly::DataStorage::S3DataStore.new
      c.datastore.configure do |d|
        d.bucket_name = 'my_s3_bucket_name'
        d.access_key_id = ENV['S3_KEY'] || raise("ENV variable 'S3_KEY' needs to be set")
        d.secret_access_key = ENV['S3_SECRET'] || raise("ENV variable 'S3_SECRET' needs to be set")
      end
    # and filesystem for other environments
    else
      c.datastore.configure do |d|
        d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
      end
    end

We've left the datastore as {Dragonfly::DataStorage::FileDataStore FileDataStore} for non-production environments.

As you can see we've used `ENV` to store the S3 access key and secret to avoid having them in the repository.
Heroku has a {http://docs.heroku.com/config-vars way of setting these} using the command line (we only have to do this once).

From your app's directory:

    heroku config:add S3_KEY=XXXXXXXXX S3_SECRET=XXXXXXXXXX

Obviously you replace 'XXXXXXXXX' with your access key and secret.

Now you can benefit use Dragonfly in the normal way, benefitting from super-fast images served straight from Heroku's cache!

The only downside is that Heroku's cache is cleared every time you deploy, so if this is an issue you may want to look into using something like 
a Memcached add-on, or maybe an after-deploy hook for hitting specific Dragonfly urls you want to cache, etc.
It won't be a problem for most sites though.

Serving attachments with no processing
--------------------------------------

Generating test data
--------------------

Text image replacement
----------------------
