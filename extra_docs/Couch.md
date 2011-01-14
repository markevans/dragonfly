CouchDB
=====
Dragonfly can be used with any ActiveModel-compatible model, and so you can use it with CouchDB using [CouchRest::Model](https://github.com/couchrest/couchrest_model).

Since CouchDB allows you to store files directly on documents as attachments, you can also use the supplied {Dragonfly::DataStorage::CouchDataStore CouchDataStore}.
which allows storing files as attachments directly on documents.

For more info about ActiveModel, see {file:Models}.

For more info about using the Couch data store, see {file:DataStorage}.

Example setup in Rails, using CouchRest::Model
-------------------------------------
In config/initializers/dragonfly.rb:

    require 'dragonfly'

    app = Dragonfly[:images]

    # Get database config from config/couchdb.yml
    couch_settings = YAML.load_file(Rails.root.join('config/couchdb.yml'))[Rails.env]

    # Configure to use ImageMagick, Rails defaults, and the Couch data store
    app.configure_with(:imagemagick)
    app.configure_with(:rails) do |c|
      c.datastore = Dragonfly::DataStorage::CouchDataStore.new(
        :host => couch_settings['host'],
        :port => couch_settings['port'],
        :username => couch_settings['username'],
        :password => couch_settings['password'],
        :database => couch_settings['database']
      )
    end

    # Allow all CouchRest::Model models to use the macro 'image_accessor'
    app.define_macro(CouchRest::Model::Base, :image_accessor)

    # ... any other setup, see Rails docs

Then in models:

    class Album < CouchRest::Model::Base
      property :cover_image_uid
      image_accessor :cover_image

      # ...
    end

See {file:Models} for more info.
