Encoding
========

Changing the format of data, but not changing the data itself,
e.g. converting to gif format, comes under the banner of Encoding.

You can register as many encoders as you like.

Let's say we have a Dragonfly app

    app = Dragonfly[:images]

and an image object (actually a {Dragonfly::Job Job} object)...

    image = app.fetch('some/uid')

...OR a Dragonfly model accessor...

    image = @album.cover_image

We can encode it to any format registered with the encoder.

RMagickEncoder
----------------
The {Dragonfly::Encoding::RMagickEncoder RMagickEncoder} is registered by default by
the {Dragonfly::Config::RMagick RMagick configuration} used by 'dragonfly/rails/images'.

If not already registered:

    app.encoder.register(Dragonfly::Encoding::RMagickEncoder)

gives us:

    image.encode(:jpg)
    image.encode(:gif)
    image.encode(:png)
    image.encode(:tiff)

and various other formats (see {Dragonfly::Encoding::RMagickEncoder RMagickEncoder})

Lazy evaluation
---------------

    gif_image = image.encode(:gif)

doesn't actually do anything until you call something on the returned {Dragonfly::Job Job} object, like `url`, `data`, etc.

Bang method
-----------

    image.encode!(:gif)

modifies the image object itself, rather than returning a new object.

Custom Encoders
---------------

To register a custom encoder, for e.g. pdf format:

    app.encoder.add do |temp_object, format|
      throw :unable_to_handle unless format == :pdf
      # use temp_object.data, temp_object.path, temp_object.file, etc.
      SomeLibrary.convert_to_pdf(temp_object.data)
      # return a String, File or Tempfile
    end

    pdf_image = image.encode(:pdf)

If `:unable_to_handle` is thrown, the next most recently registered encoder is used, and so on.

Alternatively you can create a class like the RMagick one above, which implements the method `encode`, and register this.

    class MyEncoder

      def encode(temp_object, format, *args)
        SomeLib.encode(temp_object.data, format, *args)
      end

    end

    app.encoder.register(MyEncoder)

    pdf_image = image.encode(:pdf, :some => :args)
