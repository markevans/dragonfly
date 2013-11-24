Dragonfly
===========
Hello!!
Dragonfly is a highly customizable ruby gem for handling images and other attachments and is already in use on thousands of websites.

If you want to generate image thumbnails in Rails ...
```ruby
class User < ActiveRecord::Base  # model
  dragonfly_accessor :photo
end
```
```erb
<%= image_tag @user.photo.thumb('300x200#')  # view  %>
```

... or generate text images on-demand in Sinatra ...
```ruby
get "/:text" do |text|
  Dragonfly.app.generate(:text, text, "font-size" => 32).to_response(env)
end
```

... or just generally manage attachments in your web app ...
```ruby
wav = Dragonfly.app.fetch_url("http://free.music/lard.wav")  # GET from t'interwebs
mp3 = wav.to_mp3  # to_mp3 is a custom processor
uid = mp3.store   # store in the configured datastore, e.g. S3

url = Dragonfly.app.remote_url_for(uid)  # ===> http://s3.amazon.com/my-stuff/lard.mp3
```

... then Dragonfly is for you! See [the documentation](http://markevans.github.io/dragonfly) to get started!

Documentation
=============
<a href="http://markevans.github.io/dragonfly"><big><strong>THE MAIN DOCUMENTATION IS HERE!!!</strong></big></a>

<a href="http://rubydoc.info/github/markevans/dragonfly/frames">RDoc documentation is here</a>

Dragonfly has changed somewhat since version 0.9 - if for whatever reason you can't upgrade, then
<a href="http://markevans.github.io/dragonfly/v0.9.15">the docs for version 0.9.x are here</a>.

Installation
============

    gem install dragonfly

or in your Gemfile
```ruby
gem 'dragonfly', '~> 1.0.0'
```

Require with
```ruby
require 'dragonfly'
```

Plugins and Add-ons
===================
See [the Add-ons wiki](http://github.com/markevans/dragonfly/wiki/Dragonfly-add-ons).

Please feel free to contribute!!

Issues
======
Please use the <a href="http://github.com/markevans/dragonfly/issues">github issue tracker</a> if you have any issues.

Suggestions/Questions
=====================
<a href="http://groups.google.com/group/dragonfly-users">Google group dragonfly-users</a>

Credits
=======
[Mark Evans](http://github.com/markevans) (author) with awesome contributions from
<a href="https://github.com/markevans/dragonfly/graphs/contributors">these guys</a>
