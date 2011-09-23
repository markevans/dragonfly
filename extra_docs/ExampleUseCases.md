Example Use Cases
=================
Below are a number of examples of uses for Dragonfly which differ slightly from the standard image resizing with model attachments.

Non-image attachments in Rails
------------------------------
When using `'dragonfly/rails'images'` or similar configuration, if you're not calling `thumb`, `width`
or other image-related methods on your content, then non-image attachments should _just work_.

    class User
      image_accessor :mugshot
    end

    user.mugshot = Rails.root.join('some/text_file.txt')
    user.save!
    user.mugshot.url   # /media/BAsfsdfajkl....

Furthermore, the imagemagick configuration gives you an `image?` analyser method which always returns a boolean
so you can still make a thumbnail if it is an image

    user.mugshot.thumb!('400x300#') if user.mugshot.image?

`'dragonfly/rails/images'` also gives you a `file_accessor` macro which is actually just the same as `image_accessor`,
but a bit more meaningful when not dealing with images

    class User
      file_accessor :mugshot
    end

You can always define your own macro for dealing with non-image attachments:

    Dragonfly[:my_app].define_macro(ActiveRecord::Base, :attachment_accessor)

    class User
      attachment_accessor :mugshot
    end

see {file:Models} for how to define macros with non-ActiveRecord libraries.

Quick custom image processing in Rails
--------------------------------------
With the imagemagick configuration, we can easily use `convert` to do some custom processing, e.g. in the view:

    <%= image_tag @user.mugshot.thumb('300x300#').convert('-blur 4x2').url %>

If we use this a lot, we can define a shortcut for it - in config/initializers/dragonfly.rb:

    Dragonfly[:images].configure do |c|
      c.job :blurred_square do |size|
        process :resize_and_crop, :width => size, :height => size
        process :convert, '-blur 4x2'
      end
    end

then in the view:

    <%= image_tag @user.mugshot.blurred_square(300).url %>

See {file:ImageMagick} for more info.

Using Javascript to generate on-the-fly thumbnails in Rails
-----------------------------------------------------------
Supposing we have a `Pancake` model with an image attachment

    pancake = Pancake.create! :image => Pathname.new('path/to/pancake.png')

Setting the attachment sets the uid field (this example uses the {file:DataStorage#File\_datastore FileDataStore})

    pancake.image_uid    # '2011/04/27/17_04_32_705_pancake.png'

We can set up a Dragonfly endpoint in routes.rb for generating thumbnails:

    match '/thumbs/:geometry' => app.endpoint { |params, app|
      app.fetch(params[:uid]).thumb(params[:geometry])
    }

NOTE: if you use `do`...`end` here instead of curly braces, make sure you put brackets around the arguments to `match`,
otherwise Ruby will parse it incorrectly

If we have access to the image uid in javascript, we can create the url like so:

    var url = '/thumbs/400x300?uid=' + uid

Then we can get the content with ajax, create an img tag, etc.

NOTE: in the above example we've put the uid in the query string and not the path because the dot in it confuses Rails' pattern recognition.
You could always put it in the path and escape/unescape it either side of the request.

Also javascript's built-in `encodeURIComponent` function may be useful when Rails has difficulty matching routes due to special characters like '#' and '/'.

Text generation with Sinatra
----------------------------
We can easily generate on-the-fly text with Sinatra and the {Dragonfly::ImageMagick::Generator ImageMagick Generator}:

    require 'rubygems'
    require 'sinatra'
    require 'dragonfly'

    app = Dragonfly[:images].configure_with(:imagemagick)

    get '/:text' do |text|
      app.generate(:text, text, :font_size => 30).to_response(env)
    end

When we visit '/hello!' we get a generated image of the text "hello!".

See {file:ImageMagick#Generator} for more details.

Creating a Dragonfly plugin
---------------------------
You can create custom {file:DataStorage#Custom\_datastore data stores}, {file:Processing#Custom\_Processors processors},
{file:Encoding#Custom\_Encoders encoders}, {file:Analysers#Custom\_Analysers analysers} and {file:Generators#Custom\_Generators generators}, and
then tie them all together with a {file:Configuration#Custom\_Saved\_Configuration saved configuration}.

See [Dragonfly-RMagick](http://github.com/markevans/dragonfly-rmagick) for an example.
NOTE: you will probably want to create classes and modules in your own namespace, rather than the `Dragonfly` namespace (even though Dragonfly-RMagick uses it).
