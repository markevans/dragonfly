Dragonfly
===========

Dragonfly is a <a href="http://rack.rubyforge.org">Rack</a> framework for on-the-fly processing and encoding.
It can be used with ActiveRecord, Mongoid, or any ActiveModel compliant model for easy image handling in your web app.

For the lazy Rails 3 user...
----------------------------
**Gemfile**:

    gem 'rmagick',    :require => 'RMagick'
    gem 'rack-cache', :require => 'rack/cache'
    gem 'dragonfly'

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

NB: REMEMBER THE MULTIPART BIT!!!

**View** (to display):

    <%= image_tag @album.cover_image.url %>
    <%= image_tag @album.cover_image.thumb('400x200#').url %>
    <%= image_tag @album.cover_image.jpg.url %>
    <%= image_tag @album.cover_image.process(:greyscale).encode(:tiff).url %>
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
