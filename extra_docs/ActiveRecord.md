ActiveRecord Extensions
=======================

Dragonfly provides a module that extends ActiveRecord so that you can access Dragonfly objects as if they were just another model attribute.

Registering with ActiveRecord
-----------------------------
Suppose we have a dragonfly app
    app = Dragonfly::App[:my_app_name]

First extend activerecord

    ActiveRecord::Base.extend Dragonfly::ActiveRecordExtensions

Now register the app, giving the prefix for defining accessor methods (in this case 'image')

      ActiveRecord::Base.register_dragonfly_app(:image, app)

Adding accessors
----------------
Now we have the method `image_accessor` available in our model classes, which we can use as many times as we like

    class Album
      image_accessor :cover_image
      image_accessor :band_photo  # Note: this is a different image altogether, not a thumbnail of cover_image
    end

For each accessor, we need a database field ..._uid, as a string, so in our migrations:

    class MyMigration < ActiveRecord::Migration

      def self.up
        add_column :albums, :cover_image_uid, :string
        add_column :albums, :band_photo_uid, :string
      end

      def self.down
        remove_column :albums, :cover_image_uid
        remove_column :albums, :band_photo_uid
      end

    end

Using the accessors
-------------------

We can use the attribute much like other other active record attributes:

    album = Album.new
    
    album.cover_image = "\377???JFIF\000\..."             # can assign as a string...
    album.cover_image = File.new('path/to/my_image.png')  # ... or as a file...
    album.cover_image = some_tempfile                     # ... or as a tempfile
    
    album.cover_image          # => #<Dragonfly::ActiveRecordExtensions::Attachment:0x103ef6128...
    
    album.cover_image = nil
    album.cover_image          # => nil
    
We can inspect properties of the attribute

    album.width                          # => 280
    album.height                         # => 140
    album.cover_image.number_of_colours  # => 34703 (can also use American spelling)
    album.mime_type                      # => 'image/png'
    
The properties available (i.e. 'width', etc.) come from the {Dragonfly} app's registered analysers - see {file:Analysers.md Analysers}.

We can play around with the data

    album.data                           # => "\377???JFIF\000\..."
    album.to_file('out.png')             # writes to file 'out.png' and returns a readable file object
    album.tempfile                       # => #<File:/var/folders/st/strHv74sH044JPabSiODz... i.e. a tempfile holding the data
    album.file                           # alias for tempfile, above
    album.path                           # => '/var/folders/st/strHv74sH044JPabSiODz...' i.e. the path of the tempfile

We can process the data

    temp_object = album.cover_image.process(:resize, :geometry => '20x20')   # returns an ExtendedTempObject, with similar properties
    temp_object.width                                                        # => 20
    album.cover_image.width                                                  # => 280 (no change)
    
    album.cover_image.process!(:resize, :geometry => '20x20')                # (operates on self)
    album.cover_image.width                                                  # => 20

The available processing methods available (i.e. 'resize', etc.) come from the {Dragonfly} app's registered processors - see {file:Processing.md Processing}

We can encode the data

    temp_object = album.cover_image.encode(:gif)   # returns an ExtendedTempObject, with similar properties
    temp_object.mime_type                          # => 'image/gif'
    album.cover_image.mime_type                    # => 'image/png' (no change)
    
    album.cover_image.encode!(:gif)                # (operates on self)
    album.cover_image.mime_type                    # => 'image/gif'

The encoding is implemented by the {Dragonfly} app's registered encoders (which will usually just be one) - see {file:Encoding.md Encoding}

If we have a combination of processing and encoding that we often use, e.g.

    album.cover_image.process(:resize_and_crop, :width => 300, :height => 200, :gravity => 'nw').encode(:gif)

then we can register a shortcut (see {file:Shortcuts.md Shortcuts}) and use that with `transform`, e.g.

    album.cover_image.transform('300x200#nw', :gif)           # returns an ExtendedTempObject, like process and encode above
    album.cover_image.transform!('300x200#nw', :gif)          # (operates on self)

Persisting
----------
When the model is saved, a before_save callback persists the data to the {App}'s configured datastore (see {file:DataStorage.md DataStorage})
The uid column is then filled in.

    album = Album.new
    
    album.cover_image_uid                                   # => nil
    
    album.cover_image = File.new('path/to/my_image.png')
    album.cover_image_uid                                   # => 'PENDING' (actually a Dragonfly::ActiveRecordExtensions::PendingUID)
    
    album.save
    album.cover_image_uid                                   # => '2009/12/05/170406_file' (some unique uid, used by the datastore)

URLs
----
Once the model is saved, we can get a url for the image (which is served by the Dragonfly {App} itself):

    album.cover_image.url                       # => '/media/2009/12/05/170406_file' (Note there is no extension)
    album.cover_image.url(:png)                 # => '/media/2009/12/05/170406_file.png'
    album.cover_image.url('300x200#nw', :gif)   # => '/media/2009/12/05/170406_file.tif?m=resize_and_crop&o[height]=...'

Note that any arguments given to `url` are of the same form as those used for `transform`, i.e. those registered as shortcuts (see {file:Shortcuts.md Shortcuts})

Validations
-----------
TODO

'Magic' Attributes
------------------
TODO

