Data Storage
============
Each dragonfly app has a key-value datastore to store the content (originals only).

Lets say we have an app

    app = Dragonfly[:my_app_name]

Then we can store data like so:

    # Can pass in a String, Pathname, File or Tempfile
    uid = app.store('SOME CONTENT')

We can also save metadata at the same time, and any other options the configured datastore accepts

    uid = app.store('SOME CONTENT',
      :meta => {:time => Time.now, :name => 'content.txt'},
      :some => 'option'
    )

We can get content with

    content = app.fetch(uid)
    content.data         # "SOME CONTENT"

We can also get the extra saved attributes

    content.meta         # {:time => Sat Aug 14 12:04:13 +0100 2010, :name => 'content.txt'}
    content.name         # 'content.txt'

We can destroy it with

    app.destroy(uid)

Serving directly from the datastore
-----------------------------------
Datastores can optionally serve data directly too, by implementing `url_for`

    app.datastore.url_for(uid, :some => 'option')   # ---> "http://some.url/thing.txt"

or (the same)

    app.remote_url_for(uid, :some => 'option')

or

    my_model.attachment.remote_url(:some => 'option')

You can create your own datastore, or use one of the provided ones as outlined below.

File datastore
--------------
The {Dragonfly::DataStorage::FileDataStore FileDataStore} stores data on the local filesystem.

It is used by default.

If for whatever reason you need to configure it again:

    # shouldn't need this - it is the default
    app.datastore = Dragonfly::DataStorage::FileDataStore.new

    app.datastore.configure do |d|
      d.root_path = '/filesystem/path/public/place'   # defaults to /var/tmp/dragonfly
      d.server_root = '/filesystem/path/public'       # filesystem root for serving from - default to nil
      d.store_meta = false                            # default to true - can be switched off to avoid
                                                      #  saving an extra .meta file if meta not needed
    end

You can serve directly from the FileDataStore if the `server_root` is set.

To customize the storage path (and therefore the uid), use the `:path` option on store

    app.store("SOME CONTENT", :path => 'some/path.txt')

To do this on a per-model basis see {file:Models#Storage_options}.

**BEWARE!!!!** you must make sure the path (which will become the uid for the content) is unique and changes each time the content
is changed, otherwise you could have caching problems, as the generated urls will be the same for the same uid.

S3 datastore
------------
To configure with the {Dragonfly::DataStorage::S3DataStore S3DataStore}:

    app.datastore = Dragonfly::DataStorage::S3DataStore.new

    app.datastore.configure do |c|
      c.bucket_name = 'my_bucket'
      c.access_key_id = 'salfjasd34u23'
      c.secret_access_key = '8u2u3rhkhfo23...'
      c.region = 'eu-west-1'                        # defaults to 'us-east-1'
      c.storage_headers = {'some' => 'thing'}       # defaults to {'x-amz-acl' => 'public-read'}
      c.url_scheme = 'https'                        # defaults to 'http'
      c.url_host = 'some.custom.host'               # defaults to "<bucket_name>.s3.amazonaws.com"
    end

You can also pass these options to `S3DataStore.new` as an options hash.

You can serve directly from the S3DataStore using e.g.

    my_model.attachment.remote_url

or with an expiring url:

    my_model.attachment.remote_url(:expires => 3.days.from_now)

or with an https url:

    my_model.attachment.remote_url(:scheme => 'https')   # also configurable for all urls with 'url_scheme'

or with a custom host:

    my_model.attachment.remote_url(:host => 'custom.domain')   # also configurable for all urls with 'url_host'

Extra options you can use on store are `:path` and `:headers`

    app.store("SOME CONTENT", :path => 'some/path.txt', :headers => {'x-amz-acl' => 'public-read-write'})

To do this on a per-model basis see {file:Models#Storage_options}.

**BEWARE!!!!** you must make sure the path (which will become the uid for the content) is unique and changes each time the content
is changed, otherwise you could have caching problems, as the generated urls will be the same for the same uid.

Mongo datastore
---------------
To configure with the {Dragonfly::DataStorage::MongoDataStore MongoDataStore}:

    app.datastore = Dragonfly::DataStorage::MongoDataStore.new

It won't normally need configuring, but if you wish to:

    app.datastore.configure do |d|
      c.host = 'http://egg.heads:5000'                  # defaults to localhost
      c.port = '27018'                                  # defaults to mongo default (27017)
      c.database = 'my_database'                        # defaults to 'dragonfly'
      c.username = 'some_user'                          # only needed if mongo is running in auth mode
      c.password = 'some_password'                      # only needed if mongo is running in auth mode
      c.connection_opts = {:name => 'prod'}             # arg gets passed to Mongo::Connection
                                                        #  or Mongo::ReplSetConnection initializer - see http://api.mongodb.org/ruby/current
      
      c.hosts = ['localhost:30000', 'localhost:30001']  # will use Mongo::ReplSetConnection instead of Mongo::Connection
    end

If you already have a mongo database or connection available, you can skip setting these and set `db` or `connection` instead.

You can also pass any options to `MongoDataStore.new` as an options hash.

You can't serve directly from the mongo datastore.

You can optionally pass in a `:content_type` option to `store` to tell it the content's MIME type.

Couch datastore
---------------
To configure with the {Dragonfly::DataStorage::CouchDataStore CouchDataStore}:

    app.datastore = Dragonfly::DataStorage::CouchDataStore.new

To configure:

    app.datastore.configure do |d|
      c.host = 'localhost'                            # defaults to localhost
      c.port = '5984'                                 # defaults to couchdb default (5984)
      c.database = 'dragonfly'                        # defaults to 'dragonfly'
      c.username = ''                                 # not needed if couchdb is in 'admin party' mode
      c.password = ''                                 # not needed if couchdb is in 'admin party' mode
    end

You can also pass these options to `CouchDataStore.new` as an options hash.

You can serve directly from the couch datastore.

You can optionally pass in a `:content_type` option to `store` to tell it what to use for its 'Content-Type' header.

Custom datastore
----------------
Data stores are key-value in nature, and need to implement 3 methods: `store`, `retrieve` and `destroy`.

    class MyDataStore

      def store(temp_object, opts={})
        # ... use temp_object.data, temp_object.file, temp_object.path, etc.
        # ... also we can use temp_object.meta and store it ...
        
        # store and return the uid
        'return_some_unique_uid'
      end

      def retrieve(uid)
        # return an array containing
        [
          content,          # either a File, String or Tempfile
          meta_data         # Hash - :name and :format are treated specially,
        ]                   #  e.g. job.name is taken from job.meta[:name]
      end

      def destroy(uid)
        # find the content and destroy
      end

    end

You can now configure the app to use your datastore:

    Dragonfly[:my_app_name].datastore = MyDataStore.new

Notice that `store` takes a second `opts` argument.
Any options, get passed here.
`:meta` is treated specially and is accessible inside `MyDataStore#store` as `temp_object.meta`

    uid = app.store('SOME CONTENT',
      :meta => {:name => 'great_content.txt'},
      :some_other => :option
    )

    # ...

You can also optionally serve data directly from the datastore if it implements `url_for`:

    class MyDataStore

      # ...

      def url_for(uid, opts={})
        "http://some.domain/#{uid}"
      end

    end
