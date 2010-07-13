Dragonfly
===========

Dragonfly is a <a href="http://rack.rubyforge.org">Rack</a> framework for on-the-fly processing and encoding.
It includes an extension for Ruby on Rails to enable easy image handling.

For the lazy Rails user
-----------------------
To use simply for image thumbnails etc. in Rails...

**environment.rb** (Rails 2.3 only):

    config.gem 'rmagick',    :lib => 'RMagick'
    config.gem 'rack-cache', :lib => 'rack/cache'
    config.gem 'dragonfly',  :version => '~>0.6.2'

**Gemfile** (Rails 3 only):

    gem 'rmagick',    :require => 'RMagick'
    gem 'rack-cache', :require => 'rack/cache'
    gem 'dragonfly', '~>0.6.2'

The above assumes that you have http://gemcutter.org as one of your gem sources.
If not you should add it, e.g. `gem source --add http://gemcutter.org` from the command line,
or add `source http://gemcutter.org` to your Gemfile.

**Initializer** (e.g. config/initializers/dragonfly.rb):

    require 'dragonfly/rails/images'

**Migration**:

    add_column :albums, :cover_image_uid, :string

**Model**:

    class Album < ActiveRecord::Base
      image_accessor :cover_image            # Defines reader/writer for cover_image
      # ...
    end

**View** (for uploading via a file field):

    <% form_for @album, :html => {:multipart => true} do |f| %>
      ...
      <%= f.file_field :cover_image %>
      ...
    <% end %>


**View** (to display):

    <%= image_tag @album.cover_image.url(:gif) %>
    <%= image_tag @album.cover_image.url('400x200') %>
    <%= image_tag @album.cover_image.url('100x100!', :png) %>
    <%= image_tag @album.cover_image.url('100x100#') %>
    <%= image_tag @album.cover_image.url('50x50+30+30sw', :tiff) %>
    <%= image_tag @album.cover_image.url(:rotate, 15) %>
    ...etc.

Using outside of rails, custom storage/processing/encoding/analysis, and more...
--------------------------------------------------------------------------------
Dragonfly is primarily a Rack app, the Rails part of it being nothing more than a separate layer on top of the main code, which means you can use it as a standalone app, or with Sinatra, Merb, etc.

It is intended to be highly customizable, and is not limited to images, but any data type that could suit on-the-fly processing/encoding.

For more info, consult the <a href="http://markevans.github.com/dragonfly">DOCUMENTATION</a>

Issues
======
Please use the <a href="http://github.com/markevans/dragonfly/issues">github issue tracker</a> if you have any issues.

Suggestions/Questions
=====================
<a href="http://groups.google.com/group/dragonfly-users">Google group dragonfly-users</a>

Credits
=======
- <a href="http://github.com/markevans">Mark Evans</a> (author)

Copyright
========

Copyright (c) 2009-2010 Mark Evans. See LICENSE for details.
