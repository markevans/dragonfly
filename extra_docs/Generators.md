Generators
==========

Unlike processors and encoders, generators create content out of nothing, rather than modifying already existing content, for example text image generation.

You can register as many generators as you like.

Given a Dragonfly app

    app = Dragonfly[:images]

we can get generated content using

    image = app.generate(:some_method, :some => :args)

where `:some_method` is added by the configured generators.

ImageMagick Generator
---------------------
See {file:ImageMagick}.

Custom Generators
-----------------
To register a single custom generator:

    app.generator.add :triangle do |height|
      SomeLibrary.create_triangle(height)     # return a String, Pathname, File or Tempfile
    end

    app.generate(:triangle, 10)      # => 'Job' object which we can get data, etc.

Or create a class like the ImageMagick one above, in which case all public methods will be counted as generator methods.

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

You can also return meta data like name and format if you return an array from the generator

    app.generator.add :triangle do |height|
      [
        SomeLibrary.create_triangle(height),
        {:name => 'triangle.png', :format => :png}
      ]
    end
