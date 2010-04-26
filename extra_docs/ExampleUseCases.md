Example Use Cases
=================

This document is concerned with different Dragonfly configurations, for various use cases.

In a Rails app the configuration would generally be done in an initializer.

In other Rack-based apps it could be config.ru, or anywhere where the application is generally set up.

Image thumbnails in Rails
-------------------------
See {file:UsingWithRails}


Image thumbnails in Rails, hosted on Heroku with S3 storage
-----------------------------------------------------------
{http://heroku.com Heroku} is a commonly used platform for hosting Rack-based websites.
The following assumes your site is set up for deployment onto Heroku.

The default configuration won't work out of the box for Heroku, because

- Heroku doesn't allow saving files to the filesystem (although it does use tempfiles)
- We won't need {http://tomayko.com/src/rack-cache/ Rack::Cache} on Heroku because it already uses the caching proxy {http://varnish.projects.linpro.no/ Varnish}, which we can make use of

Instead of the normal {Dragonfly::DataStorage::FileDataStore FileDataStore}, we can use the {Dragonfly::DataStorage::S3DataStore S3DataStore}.
Amazon's {http://aws.amazon.com/s3 S3} is a commonly used platform for storing data.

The following assumes you have an S3 account set up, and know your provided 'access key' and 'secret'.

### Rails 2.3

environment.rb:

    config.gem 'rmagick', :lib => 'RMagick'
    config.gem 'dragonfly'

and
.gems:

    dragonfly

### Rails 3

Gemfile:

    gem 'rmagick', :require => 'RMagick'
    gem 'dragonfly'

### All versions

Initializer (e.g. config/initializers/dragonfly.rb):

    Dragonfly::App[:images].configure_with(Dragonfly::Config::HerokuRailsImages, 'my_bucket_name')

The datastore remains as the {Dragonfly::DataStorage::FileDataStore FileDataStore} for non-production environments.

We don't store the S3 access key and secret in the repository, rather we use Heroku's
{http://docs.heroku.com/config-vars config variables} using the command line (we only have to do this once).

From your app's directory:

    heroku config:add S3_KEY=XXXXXXXXX S3_SECRET=XXXXXXXXXX

Obviously you replace 'XXXXXXXXX' with your access key and secret.

Now you can benefit use Dragonfly in the normal way, benefitting from super-fast images served straight from Heroku's cache!

NOTE: HEROKU'S CACHE IS CLEARED EVERY TIME YOU DEPLOY.
If this is an issue you may want to look into using something like a Memcached add-on, or maybe an after-deploy hook for hitting specific Dragonfly urls you want to cache, etc.
It won't be a problem for most sites though.


Attaching files to ActiveRecord models with no processing or encoding
---------------------------------------------------------------------
Although Dragonfly is normally concerned with processing and encoding, you may want to just use it with arbitrary uploaded files
(e.g. .doc, .xls, .pdf files, etc.) without processing or encoding them, so as to still benefit from the {file:ActiveRecord ActiveRecord Extensions} API.

The below shows how to do it in Rails, but the principles are the same in any context.
Let's generate a configuration for a Dragonfly App called 'attachments'

    ./script/generate dragonfly_app attachments

This generates an initializer for configuring the Dragonfly App 'attachments'.

We won't be using RMagick or Rack::Cache (as there is no processing), so our environment.rb only has:

    config.gem 'dragonfly',  :source => 'http://gemcutter.org'

and in the generated configuration, we DELETE the line

    app.configure_with(Dragonfly::Config::RMagickImages)

Then in the configure block, we add the lines

    c.url_handler.configure do |u|
      # ...
      u.protect_from_dos_attacks = false
    end
    c.register_analyser(Dragonfly::Analysis::FileCommandAnalyser)
    c.register_encoder(Dragonfly::Encoding::TransparentEncoder)

We don't need to protect the urls from Denial-of-service attacks as we aren't doing any expensive processing.
The {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} is needed to know the mime-type of the content,
and the {Dragonfly::Encoding::TransparentEncoder TransparentEncoder} is like a 'dummy' encoder which does nothing
(the way to switch off encoding may change in the future).

If a user uploads a file called 'report.pdf', then normally the original file extension will be lost.
Thankfully, to record it is as easy as adding an 'ext' column as well as the usual uid column to our migration
(see {file:ActiveRecord} for more info about 'magic attributes'):

    add_column :my_models, :attachment_uid, :string
    add_column :my_models, :attachment_ext, :string
    
Then we include a helper method in our model for setting the correct file extension when we link to the attachment:

    class MyModel < ActiveRecord::Base

      attachment_accessor :attachment
      
      def url_for_attachment
        attachment.url :format => attachment_ext
      end
    end

Now we can add links to the attached file in our views:

    <%= link_to 'Attachment', @my_model.url_for_attachment %>


Generating test data
--------------------
We may want to generate a load of test data in a test / populate script.

Each {Dragonfly::App Dragonfly App} has a 'generate' method, which returns an {Dragonfly::ExtendedTempObject ExtendedTempObject} with generated data.
The actual generation is delegated to the registered processors (along with any args passed in).

For example, if our app is registered with the {Dragonfly::Processing::RMagickProcessor RMagickProcessor} (which is already done if using with one of
the Rails helper files/generators)

    Dragonfly::App[:my_app].register_processor(Dragonfly::Processing::RMagickProcessor)

then we can generate images of different sizes/formats):

    image = Dragonfly::App[:my_app].generate(300, 200)       # creates a png image of size 300x200 (as an ExtendedTempObject)
    image.to_file('out.png')                                 # writes to file 'out.png'
    image = Dragonfly::App[:my_app].generate(50, 50, :gif)   # creates a gif image of size 50x50


Text image replacement
----------------------
A common technique for making sure a specific font is displayed on a website is replacing text with images.

We can easily use Dragonfly to do this on-the-fly.

The {Dragonfly::Processing::RMagickProcessor RMagickProcessor} has a 'text' method, which takes content in the form of text,
and creates an image of the text, given the options passed in.

We can also make use of the simple {Dragonfly::DataStorage::TransparentDataStore TransparentDataStore}, where rather than fetch
data for a given uid, the uid IS the data.

The configuration will look something like:

    Dragonfly::App[:text].configure do |c|
      c.datastore = Dragonfly::DataStorage::TransparentDataStore.new
      c.register_analyser(Dragonfly::Analysis::FileCommandAnalyser)
      c.register_processor(Dragonfly::Processing::RMagickProcessor)
      c.register_encoder(Dragonfly::Encoding::RMagickEncoder)
      c.parameters.configure do |p|
        p.default_format = :png
        p.default_processing_method = :text
      end
    end

We need the {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} for mime-type analysis.

Then when we visit a url like

    url = Dragonfly::App[:text].url_for('some text', :processing_options => {:font_size => 30, :font_family => 'Monaco'})

we get a png image of the text. We could easily wrap this in some kind of helper if we use it often.

