Generators
==========

Unlike processors and encoders, generators create content out of nothing, rather than modifying already existing content.
An example is text image generation.

Given a Dragonfly app

    app = Dragonfly[:images]

we can get generated content using

    image = app.generate(:some_method, :some => :args)

where `:some_method` is added by the configured generators.

The {Dragonfly::Config::RMagick RMagick configuration} (as used by the file 'dragonfly/rails/images'), registers the {Dragonfly::Generation::RMagickGenerator RMagickGenerator} for you.

RMagickGenerator
----------------
If not already registered:

    app.generator.register(Dragonfly::Generation::RMagickGenerator)

gives us these methods:

    image = app.generate(:plasma, 600, 400, :gif)       # generate a 600x400 plasma image, last arg defaults to :png

