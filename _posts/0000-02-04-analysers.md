---
layout: default
title:  "Analysers"
tag: customization
---

# Analysers
An Analyser analyses a particular property of a piece of content, e.g. the width of an image, the bitrate of an audio file, etc.

One can be added using a block
{% highlight ruby %}
Dragonfly.app.configure do
  analyser :depth do |content|
    # ...
  end
  # ...
end
{% endhighlight %}

or providing an object that responds to `call` (`MyAnalyser` in this case)
{% highlight ruby %}
Dragonfly.app.configure do
  analyser :depth, MyAnalyser
  # ...
end
{% endhighlight %}

## Using the analyser
The analyser is available as a method to `Job` objects

{% highlight ruby %}
image = Dragonfly.app.fetch('some/uid')
image.depth
{% endhighlight %}

and `Attachment` objects

{% highlight ruby %}
image = my_model.photo
image.depth
{% endhighlight %}

## Implementing the analyser
The `content` object yielded to the block/`call` method is a <a href="http://rdoc.info/github/markevans/dragonfly/Dragonfly/Content" target="_blank">Dragonfly::Content - see the doc</a> for methods it provides.

### Returning the property
Simply return the calculated property. You will probably want to use one of the `Content` methods for getting the data such as `data` (String), `file`, `path`, etc.

{% highlight ruby %}
analyser :depth do |content|
  SomeLibrary.get_depth(content.data)
end
{% endhighlight %}

### Using shell commands
To use the shell, you can use `Content#shell_eval`

{% highlight ruby %}
analyser :depth do |content|
  content.shell_eval do |path|
    "/usr/bin/get_depth #{path}"  # The command sent to the command line
  end
end
{% endhighlight %}

The yielded `path` above will always exist.

### Using pre-registered analysers
To use a pre-registered analyser, use `Content#analyse`

{% highlight ruby %}
analyser :bytes_per_pixel do |content|
  num_pixels = content.analyse(:width) * content.analyse(:height)
  content.size.to_f / num_pixels
end
{% endhighlight %}

## ImageMagick
The ImageMagick plugin adds a few analysers - see [the doc]({{ site.baseurl }}{% post_url 0000-01-05-imagemagick %}) for more details.

## "Magic" Model Attributes
To automatically store analysed properties in your model see [Models - Magic Attributes]({{ site.baseurl }}{% post_url 0000-01-04-models %}#magic-attributes)
