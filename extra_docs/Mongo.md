Mongo
=====
Dragonfly can be used with any ActiveModel-compatible model, therefore libraries like [Mongoid](http://mongoid.org) work out of the box.

Furthermore, Mongo DB has support for storing blob-like objects directly in the database (using MongoDB 'GridFS'),
so you can make use of this with the supplied {Dragonfly::DataStorage::MongoDataStore MongoDataStore}.

For more info about ActiveModel, see {file:Models}.

For more info about using the Mongo data store, see {file:DataStorage}.

Example setup in Rails, using Mongoid
-------------------------------------
In config/initializers/dragonfly.rb:

    require 'dragonfly'

    app = Dragonfly[:images]

    # Configure to use ImageMagick, Rails defaults, and the Mongo data store
    app.configure_with(:imagemagick)
    app.configure_with(:rails) do |c|
      c.datastore = Dragonfly::DataStorage::MongoDataStore.new :db => Mongoid.database
    end

    # Allow all mongoid models to use the macro 'image_accessor'
    app.define_macro_on_include(Mongoid::Document, :image_accessor)

    # ... any other setup, see Rails docs

Then in models:

    class Album
      include Mongoid::Document

      field :cover_image_uid
      image_accessor :cover_image

      # ...
    end

See {file:Models} for more info.
