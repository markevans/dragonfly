Processing
==========

Changing data in some way, e.g. resizing an image, comes under the banner of Processing.

You can register as many processors as you like.

Let's say we have a Dragonfly app

    app = Dragonfly[:images]

and an image object (actually a {Dragonfly::Job Job} object)...

    image = app.fetch('some/uid')

...OR a Dragonfly model accessor...

    image = @album.cover_image

We can process it using any processing methods that have been registered with the processor.

RMagickProcessor
----------------
The {Dragonfly::Processing::RMagickProcessor RMagickProcessor} is registered by default by
the {Dragonfly::Config::RMagick RMagick configuration} used by 'dragonfly/rails/images'.

If not already registered:

    app.processor.register(Dragonfly::Processing::RMagickProcessor)

gives us these methods:

    image.process(:thumb, '400x300#')            # see below

    image.process(:crop, :width => 40, :height => 50, :x => 20, :y => 30)
    image.process(:crop, :width => 40, :height => 50, :gravity => 'ne')

    image.process(:flip)                         # flips it vertically
    image.process(:flop)                         # flips it horizontally

    image.process(:greyscale, :depth => 128)     # default depth 256

    image.process(:resize, '40x40')
    image.process(:resize_and_crop, :width => 40, :height=> 50, :gravity => 'ne')

    image.process(:rotate, 45, :background_colour => 'transparent')   # default bg black

    image.process(:vignette)                     # options :x, :y, :radius, :sigma

The method `thumb` takes a geometry string and calls `resize`, `resize_and_crop` or `crop` accordingly.

    image.process(:thumb, '400x300')             # calls resize

Below are some examples of geometry strings:

    '400x300'            # resize, maintain aspect ratio
    '400x300!'           # force resize, don't maintain aspect ratio
    '400x'               # resize width, maintain aspect ratio
    'x300'               # resize height, maintain aspect ratio
    '400x300>'           # resize only if the image is larger than this
    '400x300<'           # resize only if the image is smaller than this
    '50x50%'             # resize width and height to 50%
    '400x300^'           # resize width, height to minimum 400,300, maintain aspect ratio
    '2000@'              # resize so max area in pixels is 2000
    '400x300#'           # resize, crop if necessary to maintain aspect ratio (centre gravity)
    '400x300#ne'         # as above, north-east gravity
    '400x300se'          # crop, with south-east gravity
    '400x300+50+100'     # crop from the point 50,100 with width, height 400,300

Lazy evaluation
---------------

    new_image = image.process(:some_method)

doesn't actually do anything until you call something on the returned {Dragonfly::Job Job} object, like `url`, `data`, etc.

Bang method
-----------

    image.process!(:some_method)

modifies the image object itself, rather than returning a new object.

Custom Processors
-----------------

To register a single custom processor:

    app.processor.add :watermark do |temp_object, *args|
      # use temp_object.data, temp_object.path, temp_object.file, etc.
      SomeLibrary.add_watermark(temp_object.data, 'some/watermark/file.png')
      # return a String, File or Tempfile
    end

    new_image = image.process(:watermark)

You can create a class like the RMagick one above, in which case all public methods will be counted as processing methods.
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
