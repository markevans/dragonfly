Analysers
=========

Analysing data for things like width, mime_type, etc. come under the banner of Analysis.

You can register as many analysers as you like.

Let's say we have a Dragonfly app

    app = Dragonfly[:images]

and an image object (actually a {Dragonfly::Job Job} object)...

    image = app.fetch('some/uid')

...OR a Dragonfly model accessor...

    image = @album.cover_image

We can analyse it using any analysis methods that have been registered with the analyser.

RMagickAnalyser
---------------
The {Dragonfly::Analysis::RMagickAnalyser RMagickAnalyser} is registered by default by the
{Dragonfly::Config::RMagick RMagick configuration} used by 'dragonfly/rails/images'.

If not already registered:

    app.analyser.register(Dragonfly::Analysis::RMagickAnalyser)

gives us these methods:

    image.width               # => 280
    image.height              # => 355
    image.aspect_ratio        # => 0.788732394366197
    image.portrait?           # => true
    image.landscape?          # => false
    image.depth               # => 8
    image.number_of_colours   # => 34703
    image.format              # => :png

FileCommandAnalyser
-------------------
The {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} is registered by default by the
{Dragonfly::Config::Rails Rails configuration} used by 'dragonfly/rails/images'.

As the name suggests, it uses the UNIX 'file' command.

If not already registered:

    app.analyser.register(Dragonfly::Analysis::FileCommandAnalyser)

gives us:

    image.mime_type    # => 'image/png'

It doesn't use the filesystem by default (it operates on in-memory strings), but we can make it do so by using

    app.analyser.register(Dragonfly::Analysis::FileCommandAnalyser) do |a|
      a.use_filesystem = true
    end

Custom Analysers
----------------

To register a single custom analyser:

    app.analyser.add :wobbliness do |temp_object|
      # can use temp_object.data, temp_object.path, temp_object.file, etc.
      SomeLibrary.assess_wobbliness(temp_object.data)
    end

    image.wobbliness    # => 71

You can create a class like the RMagick one above, in which case all public methods will be counted as analysis methods.
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
