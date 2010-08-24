Using with Models
=================

You can extend ActiveModel-compatible models to make working with content such as images
as easy as working with strings or numbers!

The examples below assume an initialized Dragonfly app, e.g.

    app = Dragonfly[:images]

ActiveRecord
------------
If you've required 'dragonfly/rails/images', then the following step will be already done for you.
Otherwise:

    app.define_macro(ActiveRecord::Base, :image_accessor)

defines the macro `image_accessor` on any ActiveRecord models.

Mongoid
-------

    app.define_macro_on_include(Mongoid::Document, :image_accessor)

defines the macro `image_accessor` on any models that include `Mongoid::Document`

Adding accessors
----------------
Now we have the method `image_accessor` available in our model classes, which we can use as many times as we like

    class Album
      image_accessor :cover_image
      image_accessor :band_photo  # Note: this is a different image altogether, not a thumbnail of cover_image
    end

Each accessor (e.g. `cover_image`) depends on a string field to actually hold the datastore uid,
named by appending the suffix `_uid` (e.g. `cover_image_uid`).

For example, ActiveRecord models need a migration such as:

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

We can use the attribute much like other other model attributes:

    @album = Album.new

    @album.cover_image = "\377???JFIF\000\..."             # can assign as a string...
    @album.cover_image = File.new('path/to/my_image.png')  # ... or as a file...
    @album.cover_image = some_tempfile                     # ... or as a tempfile...
    @album.cover_image = @album.band_photo                 # ... or as another Dragonfly attachment

    @album.cover_image          # => #<Dragonfly::ActiveModelExtensions::Attachment:0x103ef6128...

    @album.cover_image = nil
    @album.cover_image          # => nil

We can inspect properties of the attribute

    @album.cover_image.width                          # => 280
    @album.cover_image.height                         # => 140
    @album.cover_image.number_of_colours              # => 34703
    @album.cover_image.mime_type                      # => 'image/png'

The properties available (i.e. 'width', etc.) come from the app's registered analysers - see {file:Analysers.md Analysers}.

We can play around with the data

    @album.cover_image.data                           # => "\377???JFIF\000\..."
    @album.cover_image.to_file('out.png')             # writes to file 'out.png' and returns a readable file object
    @album.cover_image.tempfile                       # => #<File:/var/folders/st/strHv74sH044JPabSiODz... a closed Tempfile object
    @album.cover_image.file                           # => #<File:/var/folders/st/strHv74sH044JPabSiODz... a readable (open) File object
    @album.cover_image.file do |f|                    # Yields an open file object, returns the return value of
      data = f.read(256)                              #  the block, and closes the file object
    end
    @album.cover_image.path                           # => '/var/folders/st/strHv74sH044JPabSiODz...' i.e. the path of the tempfile
    @album.cover_image.size                           # => 134507 (size in bytes)

We can process the data

    image = @album.cover_image.process(:thumb, '20x20')   # returns a 'Job' object, with similar properties
    image.width                                          # => 20
    @album.cover_image.width                              # => 280 (no change)

The available processing methods available (i.e. 'thumb', etc.) come from the {Dragonfly} app's registered processors - see {file:Processing.md Processing}

We can encode the data

    image = @album.cover_image.encode(:gif)   # returns a 'Job' object, with similar properties
    image.format                              # => :gif
    @album.cover_image.format                 # => :png (no change)

The encoding is implemented by the {Dragonfly} app's registered encoders (which will usually just be one) - see {file:Encoding.md Encoding}

We can use configured shortcuts for processing/encoding, and chain them:

    @album.cover_image.thumb('300x200#ne')     # => returns a 'Job' object, with similar properties

We can chain all these things much like ActiveRecord scopes:

    @album.cover_image.png.thumb('300x200#ne').process(:greyscale).encode(:tiff)

Because the processing/encoding methods are lazy, no actual processing or encoding is done until a method like `data`, `file`, `to_file`, `width`, etc. is called.
You can force the processing to be done if you must by then calling `apply`.

    @album.cover_image.process(:greyscale).apply

Persisting
----------
When the model is saved, a before_save callback persists the data to the {Dragonfly::App App}'s configured datastore (see {file:DataStorage.md DataStorage})
The uid column is then filled in.

    @album = Album.new

    @album.cover_image_uid                                   # => nil

    @album.cover_image = File.new('path/to/my_image.png')
    @album.cover_image_uid                                   # => nil

    @album.save
    @album.cover_image_uid                                   # => '2009/12/05/file.png' (some unique uid, used by the datastore)

URLs
----
Once the model is saved, we can get a url for the image (which is served by the Dragonfly {Dragonfly::App App} itself), and for its processed/encoded versions:

    @album.cover_image.url                           # => '/media/BAhbBlsHOgZmIhgy...'
    @album.cover_image.thumb('300x200#nw').url       # => '/media/BAhbB1sYusgZhgyM...'
    @album.cover_image.process(:greyscale).jpg.url   # => '/media/BnA6CnRodW1iIg8z...'

Because the processing/encoding methods (including shortcuts like `thumb` and `jpg`) are lazy, no processing or encoding is actually done.

Validations
-----------
`validates_presence_of` and `validates_size_of` work out of the box, and Dragonfly also provides `validates_property`.

    class Album

      validates_presence_of :cover_image
      validates_size_of :cover_image, :maximum => 500.kilobytes

      validates_property :format, :of => :cover_image, :in => [:jpeg, :png, :gif]
      # ..or..
      validates_property :mime_type, :of => :cover_image, :in => %w(image/jpeg image/png image/gif)

      validates_property :width, :of => :cover_image, :in => (0..400), :message => "é demais cara!"

      # ...
    end

The property argument of `validates_property` will generally be one of the registered analyser properties as described in {file:Analysers.md Analysers}.
However it would actually work for arbitrary properties, including those of non-dragonfly model attributes.

Name and extension
------------------
If the object assigned is a file, or responds to `original_filename` (as is the case with file uploads in Rails, etc.), then `name` will be set.

    @album.cover_image = File.new('path/to/my_image.png')

    @album.cover_image.name    # => 'my_image.png'
    @album.cover_image.ext     # => 'png'


'Magic' Attributes
------------------
An accessor like `cover_image` only relies on the accessor `cover_image_uid` to work.
However, in some cases you may want to record some other properties, whether it be for using in queries, or
for caching an attribute for performance reasons, etc.

For the properties `name`, `ext`, `size` and any of the registered analysis methods (e.g. `width`, etc. in the examples above),
this is done automatically for you, if the corresponding accessor exists.

For example - with ActiveRecord, given the migration:

    add_column :albums, :cover_image_width, :integer

This will automatically be set when assigned:

    @album.cover_image = File.new('path/to/my_image.png')

    @album.cover_image_width  # => 280

They can be used to avoid retrieving data from the datastore for analysis

    @album = Album.first

    @album.cover_image.width     # => 280    - no need to retrieve data - takes it from `cover_image_width`
    @album.cover_image.size      # => 134507 - but this needs to retrieve data from the data store, then analyse


Custom Model
------------
The accessors only require that your model class implements `before_save`, `before_destroy` and `validates_each`
(if using validations), as well as of course the `..._uid` field for storing the datastore uid.

Here is an example of a minimal ActiveModel `Album` model:

    class CustomModel::Base

      extend ActiveModel::Callbacks
      define_model_callbacks :save, :destroy

      include ActiveModel::Validations   # if needed

      def save
        _run_save_callbacks {
          # do some saving!
        }
      end

      def destroy
        _run_destroy_callbacks {
          # do some destroying!
        }
      end

    end

Define our `image_accessor` macro...

    app.define_macro(CustomModel::Base, :image_accessor)

...which is used by `Album`:

    class Album < CustomModel::Base

      def cover_image_uid=
        # ...
      end

      def cover_image_uid
        # ...
      end

      image_accessor :cover_image

    end
