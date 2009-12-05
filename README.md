Dragonfly
===========

Dragonfly is an on-the-fly processing/encoding framework written as a Rack application.
It includes an extension for Ruby on Rails to enable easy image handling.

For the lazy rails user
-----------------------

In environment.rb:

    config.gem 'dragonfly-rails', :lib => 'dragonfly/rails/images'
    config.middleware.use 'Dragonfly::MiddlewareWithCache', :images

Migration:

    class AddCoverImageToAlbums < ActiveRecord::Migration

      def self.up
        add_column :albums, :cover_image_uid, :string
      end

      def self.down
        remove_column :albums, :cover_image_uid
      end

    end

Model:

    class Album < ActiveRecord::Base
    
      validates_presence_of :cover_image
      validates_size_of :cover_image, :maximum => 500.kilobytes
      validates_mime_type_of :cover_image, :in => %w(image/jpeg image/png image/gif)
      
      image_accessor :cover_image            # This provides the reader/writer for cover_image
      
      image_accessor :some_other_image       # have as many as you like - each needs a xxxx_uid column as per migration above
    
    end

View (for uploading via a file field):

    <% form_for @album, :html => {:multipart => true} do |f| %>
      ...
      <%= f.file_field :cover_image %>
      ...
    <% end %>


View (to display):

    <%= image_tag @album.cover_image.url('400x200') %>
    <%= image_tag @album.cover_image.url('100x100!', :png) %>
    <%= image_tag @album.cover_image.url('100x100#') %>
    <%= image_tag @album.cover_image.url('50x50+30+30sw', :tif) %>
    <%= image_tag @album.cover_image.url(:rotate, 15) %>
    ...etc.

Using outside of rails, custom storage/processing/encoding/analysis, and more...
------------------------------------------------------------------------
Dragonfly is primarily a Rack app, the Rails part of it being nothing more than a separate layer on top of the main code, which means you can use it as a standalone app, or with Sinatra, Merb, etc.

It is intended to be highly customizable, and is not limited to images, but any data type that could suit on-the-fly processing/encoding.

The docs are in the process of being added, and will appear soon!...

Credits
=======
- <a href="http://github.com/markevans">Mark Evans</a> (author)

Copyright
========

Copyright (c) 2009 Mark Evans. See LICENSE for details.
