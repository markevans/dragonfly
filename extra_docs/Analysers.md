Analysers
=========

Analysing data for things like width, mime_type, etc. come under the banner of Analysis.

Let's say we have a dragonfly app called 'images'

    app = Dragonfly::App[:images]

Data gets passed around between the datastore, processor, analyser, etc. in the form of an {Dragonfly::ExtendedTempObject ExtendedTempObject}.

    temp_object = app.create_object(File.new('path/to/image.png'))

This object will have any methods which have been registered with the analyser. For example, registering
the {Dragonfly::Analysis::RMagickAnalyser rmagick analyser}

    app.register_analyser(Dragonfly::Analysis::RMagickAnalyser)

give us the methods `width`, `height`, `depth` and `number_of_colours` (or `number_of_colors`).

    temp_object.width        # => 280
    # ...etc.

Registering the {Dragonfly::Analysis::FileCommandAnalyser 'file' command analyser}

    app.register_analyser(Dragonfly::Analysis::FileCommandAnalyser)

gives us the method `mime_type`, which is necessary for the app to serve the file properly.

    temp_object.mime_type    # => 'image/png'

As the file command analyser is {Dragonfly::Configurable configurable}, we can configure it as we register it if we need to

    app.register_analyser(Dragonfly::Analysis::FileCommandAnalyser) do |a|
      a.file_command = '/usr/bin/file'
    end

The saved configuration {Dragonfly::Config::RMagickImages RMagickImages} registers the above two analysers automatically.

Custom Analysers
----------------

To register a custom analyser, derive from {Dragonfly::Analysis::Base Analysis::Base} and register.
Each method takes the temp_object as its argument.

    class MyAnalyser < Dragonfly::Analysis::Base
    
      def coolness(temp_object)
        # use temp_object.data, temp_object.path, etc...
        temp_object.size / 30
      end

      # ... add as many methods as you wish

    end

    app.register_analyser(MyAnalyser)
    
    temp_object = app.create_object(File.new('path/to/image.png'))
    
    temp_object.coolness     # => 2067

You can register multiple analysers.
