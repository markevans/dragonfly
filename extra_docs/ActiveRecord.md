ActiveRecord Extensions
=======================

Dragonfly provides a module that extends ActiveRecord so that you can access Dragonfly objects as if they were just another model attribute.

Registering with ActiveRecord
-----------------------------
If you've used a rails generator, or required the file 'dragonfly/rails/images.rb', then this step will be already done for you.

Suppose we have a dragonfly app

    app = Dragonfly::App[:my_app_name]

We can define an accessor on ActiveRecord models using

    Dragonfly.active_record_macro(:image, app)

The first argument is the prefix for the accessor macro (in this case 'image').

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

    album.cover_image.width                          # => 280
    album.cover_image.height                         # => 140
    album.cover_image.number_of_colours              # => 34703 (can also use American spelling)
    album.cover_image.mime_type                      # => 'image/png'
    
The properties available (i.e. 'width', etc.) come from the app's registered analysers - see {file:Analysers.md Analysers}.

We can play around with the data

    album.cover_image.data                           # => "\377???JFIF\000\..."
    album.cover_image.to_file('out.png')             # writes to file 'out.png' and returns a readable file object
    album.cover_image.tempfile                       # => #<File:/var/folders/st/strHv74sH044JPabSiODz... a closed Tempfile object
    album.cover_image.file                           # => #<File:/var/folders/st/strHv74sH044JPabSiODz... a readable (open) File object
    album.cover_image.file do |f|                    # Yields an open file object, returns the return value of
      data = f.read(256)                             #  the block, and closes the file object
    end
    album.cover_image.path                           # => '/var/folders/st/strHv74sH044JPabSiODz...' i.e. the path of the tempfile
    album.cover_image.size                           # => 134507 (size in bytes)

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
When the model is saved, a before_save callback persists the data to the {Dragonfly::App App}'s configured datastore (see {file:DataStorage.md DataStorage})
The uid column is then filled in.

    album = Album.new
    
    album.cover_image_uid                                   # => nil
    
    album.cover_image = File.new('path/to/my_image.png')
    album.cover_image_uid                                   # => 'PENDING' (actually a Dragonfly::ActiveRecordExtensions::PendingUID)
    
    album.save
    album.cover_image_uid                                   # => '2009/12/05/170406_file' (some unique uid, used by the datastore)

URLs
----
Once the model is saved, we can get a url for the image (which is served by the Dragonfly {Dragonfly::App App} itself):

    album.cover_image.url                       # => '/media/2009/12/05/170406_file' (Note there is no extension)
    album.cover_image.url(:png)                 # => '/media/2009/12/05/170406_file.png'
    album.cover_image.url('300x200#nw', :gif)   # => '/media/2009/12/05/170406_file.tif?m=resize_and_crop&o[height]=...'

Note that any arguments given to `url` are of the same form as those used for `transform`, i.e. those registered as shortcuts (see {file:Shortcuts.md Shortcuts})
These urls are what you would use in, for example, html views.

Validations
-----------
`validates_presence_of` and `validates_size_of` work out of the box, and Dragonfly provides two more,
`validates_property` and `validates_mime_type_of` (which is actually just a thin wrapper around `validates_property`).

    class Album

      validates_presence_of :cover_image
      validates_size_of :cover_image, :maximum => 500.kilobytes
      validates_mime_type_of :cover_image, :in => %w(image/jpeg image/png image/gif)
      validates_property :width, :of => :cover_image, :in => (0..400)

      # ...
    end

The property argument of `validates_property` will generally be one of the registered analyser properties as described in {file:Analysers.md Analysers}.
However it would actually work for arbitrary properties, including those of non-dragonfly model attributes.
See {Dragonfly::ActiveRecordExtensions::Validations Validations} for more info.

Name and extension
------------------
If the object assigned is a file, or responds to `original_filename` (as is the case with file uploads in Rails, etc.), then `name` and `ext` will be set.

    album.cover_image = File.new('path/to/my_image.png')
    
    album.cover_image.name    # => 'my_image.png'
    album.cover_image.ext     # => 'png'
    

'Magic' Attributes
------------------
The only model column necessary for the migration, as described above, is the uid column, e.g. `cover_image_uid`.
However, in many cases you may want to record some other properties in the database, whether it be for using in sql queries, or
for caching an attribute for performance reasons.

For the properties `name`, `ext`, `size` and any of the registered analysis methods (e.g. `width`, etc. in the examples above),
this is done automatically for you, if the corresponding column exists.
For example:

In the migration:

    add_column :albums, :cover_image_ext, :string
    add_column :albums, :cover_image_width, :integer

These are automatically set when assigned:

    album.cover_image = File.new('path/to/my_image.png')
    
    album.cover_image_ext    # => 'png'
    album.cover_image_width  # => 280
    
They can be used to avoid retrieving data from the datastore for analysis (e.g. if you've used something like S3 to store data - see {file:DataStorage.md DataStorage})

    album = Album.first
    
    album.cover_image.ext       # => 'png'  - no need to retrieve data - takes it from `cover_image_ext`
    album.cover_image.width     # => 280    - no need to retrieve data - takes it from `cover_image_width`
    album.cover_image.size      # => 134507 - but it needs to retrieve data from the data store, then analyse
