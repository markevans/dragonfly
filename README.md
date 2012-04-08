Dragonfly
===========

Dragonfly is a <a href="http://rack.rubyforge.org">Rack</a> framework for on-the-fly image handling.

Ideal for using with Ruby on Rails (2.3 and 3), Sinatra and all that gubbins.

However, Dragonfly is NOT JUST FOR RAILS, and NOT JUST FOR IMAGES!!

For the lazy Rails user...
--------------------------
**Gemfile**:

```ruby
gem 'rack-cache', :require => 'rack/cache'
gem 'dragonfly', '~>0.9.12'
```

**Initializer** (e.g. config/initializers/dragonfly.rb):

```ruby
require 'dragonfly/rails/images'
```

**Migration**:

```ruby
add_column :albums, :cover_image_uid,  :string
add_column :albums, :cover_image_name, :string  # Optional - only if you want urls
                                                # to end with the original filename
```

**Model**:

```ruby
class Album < ActiveRecord::Base
  image_accessor :cover_image            # 'image_accessor' is provided by Dragonfly
                                         # this defines a reader/writer for cover_image
  # ...
end
```

**View** (for uploading via a file field):

```erb
<% form_for @album, :html => {:multipart => true} do |f| %>
  ...
  <%= f.file_field :cover_image %>
  ...
<% end %>
```

NB: REMEMBER THE MULTIPART BIT!!!

You can avoid having to re-upload when validations fail with

```erb
  <%= f.hidden_field :retained_cover_image %>
```

remove the attachment with

```erb
  <%= f.check_box :remove_cover_image %>
```

assign from some other url with

```erb
  <%= f.text_field :cover_image_url %>
```

and display a thumbnail (on the upload form) with

```erb
  <%= image_tag @album.cover_image.thumb('100x100').url if @album.cover_image_uid %>
```

**View** (to display):

```erb
<%= image_tag @album.cover_image.url %>
<%= image_tag @album.cover_image.thumb('400x200#').url %>
<%= image_tag @album.cover_image.jpg.url %>
<%= image_tag @album.cover_image.process(:greyscale).encode(:tiff).url %>
...etc.
```

The above relies on imagemagick being installed. Dragonfly doesn't depend on it per se, but the default configuration `'dragonfly/rails/images'`
uses it. For alternative configurations, see below.

If using Capistrano with the above, you probably will want to keep the cache between deploys, so in deploy.rb:

```ruby
namespace :dragonfly do
  desc "Symlink the Rack::Cache files"
  task :symlink, :roles => [:app] do
    run "mkdir -p #{shared_path}/tmp/dragonfly && ln -nfs #{shared_path}/tmp/dragonfly #{release_path}/tmp/dragonfly"
  end
end
after 'deploy:update_code', 'dragonfly:symlink'
```

Sinatra, CouchDB, Mongo, Rack, S3, custom storage, processing, and more...
--------------------------------------------------------------------------
Dragonfly is not just for Rails - it's primarily a Rack app, so you can use it as a standalone app, or with Sinatra, Merb, etc.

It's highly customizable, and works with any data type (not just images).

For more info, consult the <a href="http://markevans.github.com/dragonfly"><big><strong>DOCUMENTATION</strong></big></a>

Add-ons
=======
For third-party add-ons, see [the Add-ons wiki](http://github.com/markevans/dragonfly/wiki/Dragonfly-add-ons)

Issues
======
Please use the <a href="http://github.com/markevans/dragonfly/issues">github issue tracker</a> if you have any issues.

Suggestions/Questions
=====================
<a href="http://groups.google.com/group/dragonfly-users">Google group dragonfly-users</a>

Credits
=======
- [Mark Evans](http://github.com/markevans) (author)

Copyright
========
Copyright (c) 2009-2010 Mark Evans. See LICENSE for details.
