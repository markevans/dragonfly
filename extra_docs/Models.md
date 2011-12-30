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

CouchRest::Model
-------
    app.define_macro(CouchRest::Model::Base, :image_accessor)

defines the macro `image_accessor` on any models inherited from `CouchRest::Model::Base`.

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
    @album.cover_image = Pathname.new('some/path.gif')     # ... or as a pathname...
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
    @album.cover_image.to_file('out.png',
      :mode => 0600,
      :mkdirs => false
    )
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

Assigning from a url
--------------------
Dragonfly provides an accessor for assigning directly from a url:

    @album.cover_image_url = 'http://some.url/file.jpg'

You can put this in a form view, e.g. in rails erb:

    <% form_for @album, :html => {:multipart => true} do |f| %>
      ...
      <%= f.text_field :cover_image_url %>
      ...
    <% end %>

Removing an attachment via a form
---------------------------------
Normally unassignment of an attachment is done like any other attribute, by setting to nil

    @album.cover_image = nil

but this can't be done via a form - instead `remove_<attachment_name>` is provided, which can be used with a checkbox:

    <%= f.check_box :remove_cover_image %>

Retaining across form redisplays
--------------------------------
When a model fails validation, you don't normally want to have to upload your attachment again, so you can avoid having to do this by
including a hidden field in your form `retained_<attribute_name>`, e.g.

    <% form_for @album, :html => {:multipart => true} do |f| %>
      ...
      <%= f.file_field :cover_image %>
      <%= f.hidden_field :retained_cover_image %>
      ...
    <% end %>

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
      validates_property :mime_type, :of => :cover_image, :as => 'image/jpeg', :case_sensitive => false

      validates_property :width, :of => :cover_image, :in => (0..400), :message => "é demais cara!"

      # ...
    end

The property argument of `validates_property` will generally be one of the registered analyser properties as described in {file:Analysers.md Analysers}.
However it would actually work for arbitrary properties, including those of non-dragonfly model attributes.

`validates_property` can also take a proc for the message, yielding the actual value and the model

    validates_property :width, :of => :cover_image, :in => (0..400),
                               :message => proc{|actual, model| "Unlucky #{model.title} - was #{actual}" }

Name and extension
------------------
If the object assigned is a file, or responds to `original_filename` (as is the case with file uploads in Rails, etc.), then `name` will be set.

    @album.cover_image = File.new('path/to/my_image.png')

    @album.cover_image.name    # => 'my_image.png'
    @album.cover_image.ext     # => 'png'

Meta data
---------
You can store metadata along with the content data of your attachment:

    @album.cover_image = File.new('path/to/my_image.png')
    @album.cover_image.meta = {:taken => Date.yesterday}
    @album.save!

    @album.cover_image.meta      # => {:model_class=>"Album",
                                 #     :model_attachment=>:cover_image,
                                 #     :taken=>Sat, 11 Sep 2010}

As you can see, a couple of things are added by the model. You can also access this directly on the {Dragonfly::Job Job} object.

    app.fetch(@album.cover_image_uid).meta     # => {:model_class=>"Album", ...}

Meta data can be useful because at the time that Dragonfly serves content, it doesn't have access to your model, but it does
have access to the meta data that was stored alongside the content, so you could use it to provide custom response headers, etc.
(see {file:Configuration}).

Callbacks
---------
**after_assign**

`after_assign` can be used to do something every time content is assigned:

    class Person
      image_accessor :mugshot do
        after_assign{|a| a.process!(:rotate, 90) }  # 'a' is the attachment itself
      end
    end

    person.mugshot = Pathname.new('some/path.png')  # after_assign callback is called
    person.mugshot = nil                            # after_assign callback is NOT called
    
Inside the block, you can call methods on the model instance directly (`self` is the model):

    class Person
      image_accessor :mugshot do
        after_assign{|a| a.process!(:rotate, angle) }
      end

      def angle
        90
      end
    end

Alternatively you can pass in a symbol, corresponding to a model instance method:

    class Person
      image_accessor :mugshot do
        after_assign :rotate_it
      end

      def rotate_it
        mugshot.process!(:rotate, 90)
      end
    end

You can register more than one `after_assign` callback.

**after_unassign**

`after_unassign` is similar to `after_assign`, but is only called when the attachment is unassigned

    person.mugshot = Pathname.new('some/path.png')  # after_unassign callback is NOT called
    person.mugshot = nil                            # after_unassign callback is called

Up-front thumbnailing
---------------------
The best way to create different versions of content such as thumbnails is generally on-the-fly, however if you _must_
create another version _on-upload_, then you could create another accessor and automatically copy to it using `copy_to`.

    class Person
      image_accessor :mugshot do
        copy_to(:smaller_mugshot){|a| a.thumb('200x200#') }
      end
      image_accessor :smaller_mugshot
    end

    person.mugshot = Pathname.new('some/400x300/image.png')
    
    person.mugshot            # ---> 400x300 image
    person.smaller_mugshot    # ---> 200x200 image

In the above example you would need both a `mugshot_uid` field and a `smaller_mugshot_uid` field on your model.

Storage options
---------------
Some datastores take options when calling `store` - you can pass these through using `storage_xxx` methods, e.g.

**storage_path**

The {Dragonfly::DataStorage::FileDataStore FileDataStore} and {Dragonfly::DataStorage::S3DataStore S3DataStore} both
can take a `:path` option to specify where to store the content (which will also become the uid for that content)

    class Person
      image_accessor :mugshot do
        storage_path{ "some/path/#{first_name}/#{rand(100)}" }  # You can call model instance methods (like 'first_name') directly
      end
    end

or

    class Person
      image_accessor :mugshot do
        storage_path :path_for_mugshot
      end
      
      def path_for_mugshot
        "some/path/#{first_name}/#{rand(100)}"
      end
    end

or you can also yield the attachment itself

        storage_path{|a| "some/path/#{a.width}x#{a.height}.#{a.format}" }

**BEWARE!!!!** you must make sure the path (which will become the uid for the content) is unique and changes each time the content
is changed, otherwise you could have caching problems, as the generated urls will be the same for the same uid.

**BEWARE No. 2!!!!** using `id` in the `storage_path` won't generally work on create, because Dragonfly stores the content in a call to `before_save`,
at which point the `id` won't yet exist.

You can pass any options through to the datastore using `storage_xxx` methods, or all at once using `storage_opts`:

    class Person
      image_accessor :mugshot do
        storage_opts do |a|
          {
            :path => "some/path/#{id}/#{rand(100)}",
            :other => 'option'
          }
        end
      end
    end

"Magic" Attributes
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

Furthermore, any magic attributes you add a field for will be added to the meta data for that attachment (and so can be used when Dragonfly serves the content
for e.g. setting custom response headers based on that meta - see {file:Configuration}).

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
