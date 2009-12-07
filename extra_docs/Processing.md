Processing
==========

Processing is changing content in some way, and does not involve encoding.
For example, resizing an image is classed as processing, whereas converting it from 'png' to 'jpeg' is classed as encoding.

All processing jobs are defined by a processing method and a processing options hash (which is passed to the method).

Let's say we have a dragonfly app called 'images'

    app = Dragonfly::App[:images]

Data gets passed around between the datastore, processor, analyser, etc. in the form of an {Dragonfly::ExtendedTempObject ExtendedTempObject}.

    temp_object = app.create_object(File.new('path/to/image.png'))

We can process this object with any of the methods which have been registered with the app's processor.
For example, registering the {Dragonfly::Processing::RMagickProcessor rmagick processor}

    app.register_processor(Dragonfly::Processing::RMagickProcessor)

give us the processing methods `resize`, `crop`, `resize_and_crop`, `rotate`, etc.

    temp_object.process(:resize, :geometry => '30x30!')        # => returns a new temp_object with width x height = 30x30
    temp_object.process!(:resize, :geometry => '30x30!')       # => resizes its own data

The saved configuration {Dragonfly::RMagickConfiguration RMagickConfiguration} registers the above processor automatically.

Custom Processing
-----------------

To register a custom processor, derive from {Dragonfly::Processing::Base Processing::Base} and register.
Each method takes the temp_object, and the (optional) processing options hash as its argument.

    class MyProcessor < Dragonfly::Processing::Base
    
      def black_and_white(temp_object, opts={})
        # use temp_object.data, temp_object.path, etc...
        # ...process and return a String, File, Tempfile or TempObject
      end

      # ... add as many methods as you wish

    end

    app.register_processor(MyProcessor)
    
    temp_object = app.create_object(File.new('path/to/image.png'))
    
    temp_object.process(:black_and_white, :some => 'option')

You can register multiple processors.

As with analysers and encoders, if the processor is {Dragonfly::Configurable configurable}, we can configure it as we register it if we need to

    app.register_processor(MyProcessor) do |p|
      p.some_attribute = 'hello'
    end
