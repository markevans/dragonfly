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

The saved configuration {Dragonfly::Config::RMagickImages RMagickImages} registers the above processor automatically.

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

    app = Dragonfly::App[:images]
    app.register_processor(MyProcessor)

You can register multiple processors.

As with analysers and encoders, if the processor is {Dragonfly::Configurable configurable}, we can configure it as we register it if we need to

    app.register_processor(MyProcessor) do |p|
      p.some_attribute = 'hello'
    end

Your new processing method is now available to use:
    
    temp_object = app.create_object(File.new('path/to/image.png'))
    temp_object.process(:black_and_white, :some => 'option')         # processed temp_object

To get the url for content processed by your custom processor, the long way is using something like:

    app.url_for('some_uid',
      :processing_method => :black_and_white,
      :processing_options => {:size => '30x30'},
      :format => :png
    )

or if using an activerecord model,

    my_model.preview_image.url('some_uid',
      :processing_method => :black_and_white,
      :processing_options => {:size => '30x30'},
      :format => :png
    )

However, this could soon get tedious if using more than once, so the best thing is to register a shortcut for it.
So in your configuration of the Dragonfly app (or in an initializer if using 'dragonfly/rails/images') you
could do something like:

    app.parameters.add_shortcut(/^bw-(\d*x\d*)$/) do |string, match_data|
      {
        :processing_method => :black_and_white,
        :processing_options => {:size => match_data[1]},
        :format => :png
      }
    end
    
Now you can get urls by using the shortcut:

    app.url_for('some_uid', 'bw-30x30')

or with activerecord:

    my_model.preview_image.url('bw-30x30')

For more information about shortcuts, see {file:Shortcuts}.
