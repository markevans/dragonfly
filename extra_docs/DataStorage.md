Data Storage
============

Each dragonfly app has a key-value datastore to store the content (originals only).

Lets say we have an app

    app = Dragonfly[:my_app_name]

Then we can store data like so:

    uid = app.store('SOME CONTENT')       # Can pass in a String, File or Tempfile

We can also save metadata at the same time, and give it a name and format (if you pass in a File object the filename is used by default)

    uid = app.store('SOME CONTENT',
      :meta => {:time => Time.now},
      :name => 'great_content.txt',
      :format => :txt
    )

We can get content with

    content = app.fetch(uid)
    content.data         # "SOME CONTENT"

We can also get the extra saved attributes

    content.meta         # {:time => Sat Aug 14 12:04:13 +0100 2010}
    content.name         # 'great_content.txt'
    content.format       # :txt

We can destroy it with

    app.destroy(uid)

You can create your own datastore, or use one of the provided ones as outlined below.

File datastore
--------------
The {Dragonfly::DataStorage::FileDataStore FileDataStore} stores data on the local filesystem.

It is used by default.

If for whatever reason you need to configure it again:

    # shouldn't need this - it is the default
    app.datastore = Dragonfly::DataStorage::FileDataStore.new

    app.datastore.configure do |d|
      d.root_path = '/my/custom/path'              # defaults to /var/tmp/dragonfly
    end


S3 datastore
------------
To configure with the {Dragonfly::DataStorage::S3DataStore S3DataStore}:

    app.datastore = Dragonfly::DataStorage::S3DataStore.new

    app.datastore.configure do |d|
      c.bucket_name = 'my_bucket'
      c.access_key_id = 'salfjasd34u23'
      c.secret_access_key = '8u2u3rhkhfo23...'
    end

You can also pass these options to `S3DataStore.new` as an options hash.


Mongo datastore
---------------
To configure with the {Dragonfly::DataStorage::MongoDataStore MongoDataStore}:

    app.datastore = Dragonfly::DataStorage::MongoDataStore.new

It won't normally need configuring, but if you wish to:

    app.datastore.configure do |d|
      c.host = 'http://egg.heads:5000'                # defaults to localhost
      c.port = '27018'                                # defaults to mongo default (27017)
      c.database = 'my_database'                      # defaults to 'dragonfly'
    end

You can also pass these options to `MongoDataStore.new` as an options hash.

Custom datastore
----------------
Data stores are key-value in nature, and need to implement 3 methods: `store`, `retrieve` and `destroy`.

    class MyDataStore

      def store(temp_object, opts={})
        # ... use temp_object.data, temp_object.file, temp_object.path, etc. ...
        # ... can also make use of temp_object.name, temp_object.format, temp_object.meta
        # store and return the uid
        'return_some_unique_uid'
      end

      def retrieve(uid)
        # return an array containing
        [
          content,            # either a File, String or Tempfile
          extra_data          # Hash with optional keys :meta, :name, :format
        ]
      end

      def destroy(uid)
        # find the content and destroy
      end

    end

You can now configure the app to use your datastore:

    Dragonfly[:my_app_name].datastore = MyDataStore.new

Notice that `store` takes a second `opts` argument.
Any options other than `meta`, `name` and `format` get passed through to here, so calling

    uid = app.store('SOME CONTENT',
      :name => 'great_content.txt',
      :some_other => :option
    )

will be split inside `store` like so:

    def store(temp_object, opts={})
      temp_object.data             # "SOME CONTENT"
      temp_object.name             # 'great_content.txt'
      opts                         # {:some_other => :option}
      # ...
    end

    # ...
