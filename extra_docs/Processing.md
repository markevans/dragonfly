Processing
==========
Registered processors allow you to modify data, e.g. resizing an image.

You can register as many processors as you like.

Let's say we have a Dragonfly app

    app = Dragonfly[:images]

and an image object (actually a {Dragonfly::Job Job} object)...

    image = app.fetch('some/uid')

...OR a Dragonfly model accessor...

    image = @album.cover_image

We can process it using any processing methods that have been registered with the processor.

Lazy evaluation
---------------

    new_image = image.process(:some_method)

doesn't actually do anything until you call something on the returned {Dragonfly::Job Job} object, like `url`, `data`, etc.

Bang method
-----------

    image.process!(:some_method)

modifies the image object itself, rather than returning a new object.

ImageMagick Processor
---------------------
See {file:ImageMagick}.

Custom Processors
-----------------

To register a single custom processor:

    app.processor.add :watermark do |temp_object, *args|
      # use temp_object.data, temp_object.path, temp_object.file, etc.
      SomeLibrary.add_watermark(temp_object.data, 'some/watermark/file.png')
      # return a String, Pathname, File or Tempfile
    end

    new_image = image.process(:watermark)

You can create a class like the ImageMagick one above, in which case all public methods will be counted as processing methods.
Each method takes the temp_object as its argument, plus any other args.

    class MyProcessor

      def coolify(temp_object, opts={})
        SomeLib.coolify(temp_object.data, opts)
      end

      def uglify(temp_object, ugliness)
        `uglify -i #{temp_object.path} -u #{ugliness}`
      end

      private

      def my_helper_method
        # do stuff
      end

    end

    app.processor.register(MyProcessor)

    new_image = image.coolify(:some => :args)

    new_image = image.uglify(:loads)
