---
layout: default
title:  "ImageMagick"
tag: main
---

# ImageMagick
ImageMagick functionality is added by configuring with the plugin
{% highlight ruby %}
Dragonfly.app.configure do
  plugin :imagemagick
end
{% endhighlight %}

Given a model attachment

{% highlight ruby %}
image = my_model.image
{% endhighlight %}

or a `Job` object created with something like

{% highlight ruby %}
image = Dragonfly.app.fetch('some/uid')
{% endhighlight %}

the ImageMagick plugin provides the following...

## Processors
### Thumb
Create a thumbnail by resizing/cropping
{% highlight ruby %}
image.thumb('40x30')
{% endhighlight %}

Below are some examples of geometry strings for `thumb`:

{% highlight ruby %}
'400x300'         # resize, maintain aspect ratio
'400x300!'        # force resize, don't maintain aspect ratio
'400x'            # resize width, maintain aspect ratio
'x300'            # resize height, maintain aspect ratio
'400x300<'        # resize only if the image is smaller than this
'400x300>'        # resize only if the image is larger than this
'50x50%'          # resize width and height to 50%
'400x300^'        # resize width, height to minimum 400,300, maintain aspect ratio
'2000@'           # resize so max area in pixels is 2000
'400x300#'        # resize, crop if necessary to maintain aspect ratio (centre gravity)
'400x300#ne'      # as above, north-east gravity
'400x300se'       # crop, with south-east gravity
'400x300+50+100'  # crop from the point 50,100 with width, height 400,300
{% endhighlight %}

You can optionally specify the output format or specify a single frame/page (e.g. for gifs/pdfs) to work on
{% highlight ruby %}
image.thumb('40x30', 'format' => 'jpg', 'frame' => 0)
{% endhighlight %}

### Encode
Change the encoding with
{% highlight ruby %}
image.encode('tiff')
{% endhighlight %}

optionally pass imagemagick arguments
{% highlight ruby %}
image.encode('jpg', '-quality 10')
{% endhighlight %}

### Rotate
Rotate a number of degrees with
{% highlight ruby %}
image.rotate(90)
{% endhighlight %}

### Convert
Perform an arbitrary imagemagick command using convert.
{% highlight ruby %}
image.convert('-sigmoidal-contrast 4,0%')
{% endhighlight %}
corresponds to the command-line

    convert <original_path> -sigmoidal-contrast 4,0% <new_path>

As with `thumb`, you can specify the output format and frame
{% highlight ruby %}
image.convert('-sigmoidal-contrast 4,0%', 'format' => 'jpg', 'frame' => 12)
{% endhighlight %}

You can also specify the delegate if needed, e.g.
{% highlight ruby %}
movie = Dragonfly.app.fetch('some/movie')
image = movie.convert('', 'delegate' => 'mpeg', 'format' => 'jpg', 'frame' => 1)
{% endhighlight %}
which would prepend `mpeg:` to the input path.

## Analysers
The following methods are provided
{% highlight ruby %}
image.width               # => 280
image.height              # => 355
image.aspect_ratio        # => 0.788732394366197
image.portrait?           # => true
image.landscape?          # => false
image.format              # => 'png'
image.image?              # => true
{% endhighlight %}

## Generators
### Text
If you have ghostscript installed on your system, you can generate text images with
{% highlight ruby %}
image = Dragonfly.app.generate(:text, "Hello there")
{% endhighlight %}

or with options
{% highlight ruby %}
image = app.generate(:text, "Hello there",
  'font-size' => 30,                 # defaults to 12
  'font-family' => 'Monaco',
  'stroke-color' => '#ddd',
  'color' => 'red',
  'font-style' => 'italic',
  'font-stretch' => 'expanded',
  'font-weight' => 'bold',
  'padding' => '30 20 10',
  'background-color' => '#efefef',   # defaults to transparent
  'format' => 'gif'                  # defaults to png
)
{% endhighlight %}

Note that the text generation options are meant to resemble css as much as possible.

You can use `padding-top`, `padding-left`, etc., as well as the standard css shortcuts for `padding` (it assumes unit is px).

An alternative for `font-family` is `font` (see [the imagemagick docs](http://www.imagemagick.org/script/command-line-options.php#font)), which could be a complete filename.
Available fonts are those available on your system.

### Plain
A plain coloured image is generated with
{% highlight ruby %}
image = Dragonfly.app.generate(:plain, 600, 400)
{% endhighlight %}

or with options
{% highlight ruby %}
image = Dragonfly.app.generate(:plain, 600, 400,
  'format' => 'jpg',
  'color' => 'rgba(40,200,30,0.5)'    # any css-style colour should work
)
{% endhighlight %}

### Plasma
Generate a fractal-like plasma image with
{% highlight ruby %}
image = Dragonfly.app.generate(:plasma, 600, 400, 'format' => 'gif')
{% endhighlight %}

The format is optional (defaults to png).

### Convert
Perform an arbitrary imagemagick generation command using convert.
{% highlight ruby %}
image = Dragonfly.app.generate(:convert, '-size 100x100 gradient:blue', 'jpg')
{% endhighlight %}
corresponds to the command-line

    convert -size 100x100 gradient:blue <path>

where path has extension 'jpg' (optional argument).

## Extra methods
### Identify
The plugin adds an `identify` method to `Job` objects and model attachments which
simply proxies to the command line and returns the output.

{% highlight ruby %}
my_model.image.identify
  # ===> "/var/tmp/dragonfly20131109-61051-de35zi.png PNG 1x1 1x1+0+0 8-bit sRGB 1c 266B 0.000u 0:00.000\n"

my_model.image.identify("-verbose")
  # ===> "Image: /var/tmp/dr..."
{% endhighlight %}

## Configuration
On configure you can specify where to find the imagemagick commands
{% highlight ruby %}
Dragonfly.app.configure do
  plugin :imagemagick,
    convert_command: "/opt/local/bin/convert",   # defaults to "convert"
    identify_command: "/opt/local/bin/identify"  # defaults to "identify"
end
{% endhighlight %}
