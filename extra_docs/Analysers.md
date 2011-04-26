Analysers
=========
Analysers are registered with Dragonfly apps for adding methods to {file:GeneralUsage Job} objects and {file:Models model attachments} such as `width`, `height`, etc.

ImageMagick Analyser
--------------------
See {file:ImageMagick}.

FileCommandAnalyser
-------------------
The {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} is registered by default by the
{Dragonfly::Config::Rails Rails configuration} used by 'dragonfly/rails/images'.

As the name suggests, it uses the UNIX 'file' command.

If not already registered:

    app.analyser.register(Dragonfly::Analysis::FileCommandAnalyser)

gives us:

    image.mime_type    # => 'image/png'

You shouldn't need to configure it but if you need to:

    app.analyser.register(Dragonfly::Analysis::FileCommandAnalyser) do |a|
      a.use_filesystem = false                 # defaults to true
      a.file_command = '/opt/local/bin/file'   # defaults to 'file'
      a.num_bytes_to_check = 1024              # defaults to 255 - only applies if not using the filesystem
    end

Custom Analysers
----------------

To register a single custom analyser:

    app.analyser.add :wobbliness do |temp_object|
      # can use temp_object.data, temp_object.path, temp_object.file, etc.
      SomeLibrary.assess_wobbliness(temp_object.data)
    end

    image.wobbliness    # => 71

You can create a class like the ImageMagick one above, in which case all public methods will be counted as analysis methods.
Each method takes the temp_object as its argument.

    class MyAnalyser

      def coolness(temp_object)
        temp_object.size / 30
      end

      def uglyness(temp_object)
        `ugly -i #{temp_object.path}`
      end

      private

      def my_helper_method
        # do stuff
      end

    end

    app.analyser.register(MyAnalyser)

    image.coolness    # => -4.1
    image.uglyness    # => "VERY"
