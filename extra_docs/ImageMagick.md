ImageMagick
===========
Either `require 'dragonfly/rails/images'` or `Dragonfly[:images].configure_with(:imagemagick)`
gives us an ImageMagick {Dragonfly::ImageMagick::Processor Processor}, {Dragonfly::ImageMagick::Encoder Encoder},
{Dragonfly::ImageMagick::Analyser Analyser} and {Dragonfly::ImageMagick::Generator Generator}.

Given a {Dragonfly::Job Job} object

    image = app.fetch('some/uid')

...OR a Dragonfly model accessor...

    image = @album.cover_image

we have the following:

Shortcuts
---------
    image.thumb('40x30')              # same as image.process(:thumb, '40x30')
    image.jpg                         # same as image.encode(:jpg)
    image.png                         # same as image.encode(:png)
    image.gif                         # same as image.encode(:gif)
    image.strip                       # same as image.process(:strip)
    image.convert('-scale 30x30')     # same as image.process(:convert, '-scale 30x30')

`thumb` and `convert` can optionally take a format (e.g. :gif) as the second argument.
Bang methods like `image.thumb!('40x30')`, `image.png!` etc. will operate on `self`.

Below are some examples of geometry strings for `thumb`:

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

Processor
---------

    image.process(:crop, :width => 40, :height => 50, :x => 20, :y => 30)
    image.process(:crop, :width => 40, :height => 50, :gravity => 'ne')

    image.process(:flip)                         # flips it vertically
    image.process(:flop)                         # flips it horizontally

    image.process(:greyscale, :depth => 128)     # default depth 256

    image.process(:resize, '40x40')
    image.process(:resize_and_crop, :width => 40, :height=> 50, :gravity => 'ne')

    image.process(:rotate, 45, :background_colour => 'transparent')   # default bg black

The method `thumb` takes a geometry string and calls `resize`, `resize_and_crop` or `crop` accordingly.

    image.process(:thumb, '400x300')             # calls resize

Encoder
-------
The {Dragonfly::ImageMagick::Encoder ImageMagick Encoder} gives us:

    image.encode(:jpg)
    image.encode(:gif)
    image.encode(:png)
    image.encode(:tiff)

and various other formats (see {Dragonfly::ImageMagick::Encoder ImageMagick Encoder}).

You can also pass additional options to the imagemagick command line:

    image.encode(:jpg, '-quality 10')

Analyser
--------
The {Dragonfly::ImageMagick::Analyser ImageMagick Analyser} gives us these methods:

    image.width               # => 280
    image.height              # => 355
    image.aspect_ratio        # => 0.788732394366197
    image.portrait?           # => true
    image.landscape?          # => false
    image.depth               # => 8
    image.number_of_colours   # => 34703
    image.format              # => :png
    image.image?              # => true - will return true or false for any content

Generator
---------
The {Dragonfly::ImageMagick::Generator ImageMagick Generator} gives us these methods:

    image = app.generate(:plain, 600, 400, 'rgba(40,200,30,0.5)')
    image = app.generate(:plain, 600, 400, '#ccc', :format => :gif)
                                                        # generate a 600x400 plain image
                                                        # any css-style colour should work

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

Note that the text generation options are meant to resemble css as much as possible. You can also use, for example, `'font-family'` instead of `:font_family`.

You can use `padding-top`, `padding-left`, etc., as well as the standard css shortcuts for `padding` (it assumes unit is px).

An alternative for `:font_family` is `:font` (see {http://www.imagemagick.org/script/command-line-options.php#font the imagemagick docs}), which could be a complete filename.
Available fonts are those available on your system.

Configuration
-------------
There are some options that can be set, e.g. if the imagemagick convert command can't be found:

    app.configure do |c|
      c.convert_command = "/opt/local/bin/convert"          # defaults to "convert"
      c.identify_command = "/opt/local/bin/identify"        # defaults to "identify"
      c.log_commands = true                                 # defaults to false
    end
