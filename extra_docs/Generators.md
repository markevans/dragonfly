Generators
==========

Unlike processors and encoders, generators create content out of nothing, rather than modifying already existing content, for example text image generation.

You can register as many generators as you like.

Given a Dragonfly app

    app = Dragonfly[:images]

we can get generated content using

    image = app.generate(:some_method, :some => :args)

where `:some_method` is added by the configured generators.

RMagickGenerator
----------------
The {Dragonfly::Generation::RMagickGenerator RMagickGenerator} is registered by default by the
{Dragonfly::Config::RMagick RMagick configuration} used by 'dragonfly/rails/images'.

If not already registered:

    app.generator.register(Dragonfly::Generation::RMagickGenerator)

gives us these methods:

    image = app.generate(:plasma, 600, 400, :gif)       # generate a 600x400 plasma image
                                                        # last arg defaults to :png

    image = app.generate(:text, "Hello there")          # an image of the text "Hello there"

    image = app.generate(:text, "Hello there",
      :font_size => 30,                                 # defaults to 12
      :font_family => 'Monaco',
      :stroke_color => '#ddd',
      :color => 'red',
      :font_style => 'italic',
      :font_stretch => 'expanded',
      :font_weight => 'bold',
      :padding => '30 20 10',
      :background_color => '#efefef',                   # defaults to transparent
      :format => :gif                                   # defaults to png
    )

Note that the options are meant to resemble css as much as possible. You can also use, for example, `'font-family'` instead of `:font_family`.

You can use `padding-top`, `padding-left`, etc., as well as the standard css shortcuts for `padding` (it assumes unit is px).

An alternative for `:font_family` is `:font` (see {http://www.imagemagick.org/RMagick/doc/draw.html#font}), which could be a complete filename.
Available fonts are those available on your system.

Custom Generators
-----------------
To register a single custom generator:

    app.generator.add :blank_image do |colour|
      SomeLibrary.create_blank_image(colour)     # return a String, File or Tempfile
    end

    app.generate(:blank_image, 'red')      # => 'Job' object which we can get data, etc.


Or create a class like the RMagick one above, in which case all public methods will be counted as generator methods.

    class RoundedCornerGenerator

      def top_left_corner(opts={})
        SomeLib.tlc(opts)
      end

      def bottom_right_corner(opts={})
        tempfile = Tempfile.new('brc')
        `some_command -c #{opts[:colour]} -o #{tempfile.path}`
        tempfile
      end

      # ...

      private

      def my_helper_method
        # do stuff
      end

    end

    app.generator.register(RoundedCornerGenerator)

    app.generate(:top_left_corner, :colour => 'green')
    app.generate(:bottom_right_corner, :colour => 'mauve')
