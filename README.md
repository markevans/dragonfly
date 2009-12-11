Dragonfly
===========

Dragonfly is an on-the-fly processing/encoding framework written as a Rack application.
It includes an extension for Ruby on Rails to enable easy image handling.

For the lazy rails user
-----------------------

environment.rb:

    config.gem 'dragonfly-rails', :lib => 'dragonfly/rails/images'
    config.middleware.use 'Dragonfly::MiddlewareWithCache', :images

Migration:

    add_column :albums, :cover_image_uid, :string

Model:

    class Album < ActiveRecord::Base
      image_accessor :cover_image            # Defines reader/writer for cover_image
      # ...
    end

View (for uploading via a file field):

    <% form_for @album, :html => {:multipart => true} do |f| %>
      ...
      <%= f.file_field :cover_image %>
      ...
    <% end %>


View (to display):

    <%= image_tag @album.cover_image.url(:gif) %>
    <%= image_tag @album.cover_image.url('400x200') %>
    <%= image_tag @album.cover_image.url('100x100!', :png) %>
    <%= image_tag @album.cover_image.url('100x100#') %>
    <%= image_tag @album.cover_image.url('50x50+30+30sw', :tif) %>
    <%= image_tag @album.cover_image.url(:rotate, 15) %>
    ...etc.

Using outside of rails, custom storage/processing/encoding/analysis, and more...
--------------------------------------------------------------------------------
Dragonfly is primarily a Rack app, the Rails part of it being nothing more than a separate layer on top of the main code, which means you can use it as a standalone app, or with Sinatra, Merb, etc.

It is intended to be highly customizable, and is not limited to images, but any data type that could suit on-the-fly processing/encoding.

For more info, consult the <a href="http://yardoc.org/docs/markevans-dragonfly">DOCUMENTATION</a>

Issues
======
Please use the <a href="http://github.com/markevans/dragonfly/issues">github issue tracker</a> if you have any issues.


Credits
=======
- <a href="http://github.com/markevans">Mark Evans</a> (author)

Copyright
========

Copyright (c) 2009 Mark Evans. See LICENSE for details.
