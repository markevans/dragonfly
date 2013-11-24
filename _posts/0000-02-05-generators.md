---
layout: default
title:  "Generators"
tag: customization
---

# Generators
A Generator creates content from nothing, e.g. text image generation, sine-wave audio generation for a given note, etc.

They work in exactly the same way as processors, except the content they receive is empty.

They can be added using a block or object that responds to `call`
{% highlight ruby %}
Dragonfly.app.configure do
  generator :text do |content, *args|
    # ...
  end

  generator :sine_wave, SineWaveGenerator.new
  # ...
end
{% endhighlight %}
<!-- *** silly asterisk highlighting -->

## Using the generator
Calling the generator on the app creates a new `Job` object

{% highlight ruby %}
job = Dragonfly.app.generate(:sine_wave, 'c')
{% endhighlight %}

## Implementing the generator
Implementing is the same as for processors (including `update_url`) - see [Processors]({{ site.baseurl }}{% post_url 0000-02-03-processors %})
and <a href="http://rdoc.info/github/markevans/dragonfly/Dragonfly/Content" target="_blank">Dragonfly::Content</a>.

### Using shell commands
To generate using the shell, you can use `Content#shell_generate`

{% highlight ruby %}
generator :sine_wave do |content, note|
  content.shell_generate :ext => 'wav' do |path|  # :ext is optional
    "/usr/local/bin/sine_wave -note #{note} -out #{path}"
  end
end
{% endhighlight %}

The yielded `path` above will always exist.

### Using pre-registered generators
To generate using a pre-registered generator, use `Content#generate!`

{% highlight ruby %}
generator :gradient do |content|
  content.generate! :convert, "-size 100x100 gradient:blue", 'jpg'
end
{% endhighlight %}

## ImageMagick
The ImageMagick plugin adds a few generators - see [the doc]({{ site.baseurl }}{% post_url 0000-01-05-imagemagick %}) for more details.
