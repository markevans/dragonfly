---
layout: default
title: Dragonfly
---

# Dragonfly
Welcome! Dragonfly is a highly customizable ruby gem which is already used on thousands of websites.

If you want to generate image thumbnails in Rails ...
{% highlight ruby %}
class User < ActiveRecord::Base  # model
  dragonfly_accessor :photo
end
{% endhighlight %}
{% highlight erb %}
<%= image_tag @user.photo.thumb('300x200#').url  # view  %>
{% endhighlight %}

... or generate text images on-demand in Sinatra ...
{% highlight ruby %}
get "/:text" do |text|
  Dragonfly.app.generate(:text, text, "font-size" => 32).to_response(env)
end
{% endhighlight %}

... or just generally manage attachments in your web app ...
{% highlight ruby %}
wav = Dragonfly.app.fetch_url("http://free.music/lard.wav")  # GET from t'interwebs
mp3 = wav.to_mp3  # to_mp3 is a custom processor
uid = mp3.store   # store in the configured datastore, e.g. S3

url = Dragonfly.app.remote_url_for(uid)  # ===> http://s3.amazon.com/my-stuff/lard.mp3
{% endhighlight %}

... then Dragonfly is for you! Use the navigation links to browse the documentation.
