Serving Content Remotely
========================

Dragonfly stores original versions of content in a datastore which could be the {file:DataStorage#File\_datastore filesystem},
{file:DataStorage#S3\_datastore S3}, etc., but when it comes to serving it, or serving a processed version
(e.g. an image thumbnail), it fetches it and serves locally from the {Dragonfly::Server dragonfly server}.

For most cases, this is the way to go - you have control over it and you can {file:Caching cache it using HTTP caching}.

However, if for whatever reason you must serve content from the datastore directly, e.g. for lightening the load on your server, Dragonfly
provides a number of ways of doing this.

Original Content
----------------
The {file:DataStorage#File\_datastore FileDataStore}, {file:DataStorage#S3\_datastore S3DataStore} and
{file:DataStorage#Couch\_datastore CouchDataStore} allow for serving data directly, so given a Dragonfly app

    app = Dragonfly[:my_app]

and the uid for some stored content

    uid = app.store(Pathname.new('some/file.jpg'))

we can get the remote url using

    app.remote_url_for(uid)            # e.g. http://my-bucket.s3.amazonaws.com/2011/04/01/03/03/05/243/file.jpg

or from a model attachment:

    my_model.attachment.remote_url     # http://my-bucket.s3.amazonaws.com/2011...

Processed Content
-----------------
If using models, the quick and easy way to serve e.g. image thumbnails remotely is to process them _on upload_
like most other attachment ruby gems (see {file:Models#Up-front_thumbnailing}),
e.g. for my avatar model,

    class Avatar
      image_accessor :image do
        copy_to(:small_image){|a| a.thumb('200x200#') }
      end
      image_accessor :small_image
    end

Then we can use `remote_url` for for each accessor.

    avatar.image.remote_url            # http://my-bucket.s3.amazonaws.com/some/path.jpg
    avatar.small_image.remote_url      # http://my-bucket.s3.amazonaws.com/some/other/path.jpg

However, this has all the limitations that come with up-front processing, such as having to regenerate the thumbnail when the size requirement changes.

Serving Processed Content *on-the-fly*
--------------------------------------
Serving processed versions of content such as thumbnails remotely is a bit more tricky as we need to upload the thumbnail
to the datastore in the on-the-fly manner.

Dragonfly provides a way of doing this using `define_url` and `before_serve` methods.

The details of keeping track of/expiring these thumbnails is up to you.

We need to keep track of which thumbnails have been already created, by storing a uid for each one.
Below is an example using an ActiveRecord 'Thumb' table to keep track of already created thumbnail uids.
It has two string columns; 'job' and 'uid'.

    app.configure do |c|
  
      # Override the .url method...
      c.define_url do |app, job, opts|
        thumb = Thumb.find_by_job(job.serialize)
        # If (fetch 'some_uid' then resize to '40x40') has been stored already, give the datastore's remote url ...
        if thumb
          app.datastore.url_for(thumb.uid)
        # ...otherwise give the local Dragonfly server url
        else
          app.server.url_for(job)
        end
      end

      # Before serving from the local Dragonfly server...
      c.server.before_serve do |job, env|
        # ...store the thumbnail in the datastore...
        uid = job.store
        
        # ...keep track of its uid so next time we can serve directly from the datastore
        Thumb.create!(
          :uid => uid,
          :job => job.serialize     # 'BAhbBls...' - holds all the job info
        )                           # e.g. fetch 'some_uid' then resize to '40x40'
      end
  
    end

This would give

    app.fetch('some_uid').thumb('40x40').url    # normal Dragonfly url e.g. /media/BAhbBls...
    
then from the second time onwards
    
    app.fetch('some_uid').thumb('40x40').url    # http://my-bucket.s3.amazonaws.com/2011...

The above is just an example - there are a number of things you could do with `before_serve` and `define_url` -
you could use e.g. Redis or some key-value store to keep track of thumbnails.
You'd also probably want a way of expiring the thumbnails or destroying them when the original is destroyed, but this
is left up to you as it's outside of the scope of Dragonfly.