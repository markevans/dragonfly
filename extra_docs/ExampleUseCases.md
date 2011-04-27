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

Quick custom processing in Rails
--------------------------------

Using Javascript to generate on-the-fly thumbnails in Rails
-----------------------------------------------------------

Text generation with Sinatra
----------------------------

Creating a Dragonfly plugin
---------------------------
