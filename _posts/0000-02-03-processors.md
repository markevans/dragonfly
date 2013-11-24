---
layout: default
title:  "Processors"
tag: customization
---

# Processors
A Processor modifies content, e.g. resizing an image, converting audio to mp3 format, etc.

They can be added using a block
{% highlight ruby %}
Dragonfly.app.configure do
  processor :shrink do |content, *args|
    # ...
  end
  # ...
end
{% endhighlight %}
<!-- *** silly asterisk highlighting -->

or providing an object that responds to `call` (`MyProcessor` in this case)
{% highlight ruby %}
Dragonfly.app.configure do
  processor :shrink, MyProcessor
  # ...
end
{% endhighlight %}

## Using the processor
The processor is available as a method to `Job` objects

{% highlight ruby %}
image = Dragonfly.app.fetch('some/uid')
smaller_image = image.shrink
{% endhighlight %}

and `Attachment` objects

{% highlight ruby %}
image = my_model.photo
smaller_image = image.shrink
{% endhighlight %}

Furthermore, a bang! method is provided, which operates on `self`
{% highlight ruby %}
image.shrink!
{% endhighlight %}

You can pass arguments, which will be passed on to the processor block
{% highlight ruby %}
processor :shrink do |content, amount, quality|
  # ...
end
{% endhighlight %}
{% highlight ruby %}
image.shrink(4, 30)
{% endhighlight %}

## Implementing the processor
The `content` object yielded to the block/`call` method is a <a href="http://rdoc.info/github/markevans/dragonfly/Dragonfly/Content" target="_blank">Dragonfly::Content - see the doc</a> for methods it provides.

The processor's job is to use methods on `content` to modify it - the return value of the processor block is not important.

### Updating content and metadata
The primary method to use to update content is `Content#update`. It can take a String, Pathname, File or Tempfile, and optionally metadata to add.

{% highlight ruby %}
processor :shrink do |content|
  # ...
  content.update(some_file, 'some' => 'meta')
end
{% endhighlight %}

Another way of updating metadata is with `add_meta`
{% highlight ruby %}
content.add_meta('some' => 'meta')
{% endhighlight %}

**NOTE** meta data should be serializable to and from JSON.

### Using shell commands
To update using the shell, you can use `Content#shell_update`

{% highlight ruby %}
processor :shrink do |content|
  content.shell_update do |old_path, new_path|
    "/usr/bin/shrink #{old_path} -o #{new_path}"  # The command sent to the command line
  end
end
{% endhighlight %}

The yielded `old_path` and `new_path` above will always exist.

### Using pre-registered processors
To update using a pre-registered processor, use `Content#process!`

{% highlight ruby %}
processor :greyscale do |content|
  content.process! :convert, "-type Grayscale"
end
{% endhighlight %}

### Updating the url
It is also possible for a processor to (optionally) update the url for a given job.
For example, suppose we have a configured url format

{% highlight ruby %}
url_format '/:basename-:style.:ext'
{% endhighlight %}

A job
{% highlight ruby %}
job = Dragonfly.app.fetch('some_uid')
{% endhighlight %}

will have a url
{% highlight ruby %}
job.url # ===> "?job=W1siZiIsInNvbWVfdWlkIl1d"
{% endhighlight %}

Here, `basename`, `style` and `ext` have not been set on the job's `url_attributes`, so they don't appear in the url.

Setting the name will set `basename` and `ext`.
{% highlight ruby %}
job.url  # ===> "?job=W1siZiIsInNvbWVfdWlkIl1d"
job.url_attributes.name = 'hello.txt'
job.url  # ===> "/hello.txt?job=W1siZiIsInNvbWVfdWlkIl1d"
{% endhighlight %}

Note that this happens automatically for models when a `xxx_name` accessor is provided.

We can tell our processor to add the `style` part of the url by implementing the method `update_url`
(note that we cannot register the processor as a block in this case)

{% highlight ruby %}
class ShrinkProcessor
  def call(content, *args)
    # ...
  end

  def update_url(attrs, *args) # attrs is Job#url_attributes, which is an OpenStruct-like object
    attrs.style = 'shrunk'
  end
end

Dragonfly.app.configure do
  processor :shrink, ShrinkProcessor.new
  # ...
end
{% endhighlight %}

Now the processor adds the 'style' part to the url

{% highlight ruby %}
job.url        # ===> "/hello.txt?job=W1siZiIsInNvbWVfdWlkIl1d"
job.shrink.url # ===> "/hello-shrunk.txt?job=W1siZiIsInNvbWVfdWlkIl1d"
{% endhighlight %}

If the processor accepts extra arguments then these are also passed to `update_url`.

## ImageMagick
The ImageMagick plugin adds a few processors - see [the doc]({{ site.baseurl }}{% post_url 0000-01-05-imagemagick %}) for more details.
