Dragonfly
===========

Dragonfly is an on-the-fly processing/encoding framework written as a Rack application.
It includes an extension for Ruby on Rails to enable easy image handling.

For the lazy rails user
-----------------------

In environment.rb:

    config.gem 'dragonfly-rails', :lib => 'dragonfly/rails/images'
    config.middleware.use 'Dragonfly::Middleware', :images

IMPORTANT: see 'Caching' below to add caching (recommended!)

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
    
    end

View (for uploading via a file field):

    <% form_for @album, :html => {:multipart => true} do |f| %>
      ...
      <%= f.file_field :cover_image %>
      ...
    <% end %>


View (to display):

    <%= image_tag @album.cover_image.url('400x200') %>
    <%= image_tag @album.cover_image.url('100x100!') %>
    <%= image_tag @album.cover_image.url('100x100#') %>
    <%= image_tag @album.cover_image.url('50x50+30+30sw') %>
    ...etc.


Caching
-------

All this processing and encoding on the fly is pretty expensive to perform on every page request.
Thankfully, HTTP caching comes to the rescue.
You could use any HTTP caching component such as Varnish, Squid, etc., but the quickest and easiest way is to use the excellent Rack::Cache, which should be adequate for most websites.

In that case, rather than the above, your `environment.rb` should contain something like this:

    config.gem 'dragonfly-rails', :lib => 'dragonfly/rails/images'
    config.gem 'rack-cache', :lib => 'rack/cache'
    config.middleware.use 'Rack::Cache',
      :verbose     => true,
      :metastore   => 'file:/var/cache/rack/meta',
      :entitystore => 'file:/var/cache/rack/body'
    config.middleware.use 'Dragonfly::Middleware', :images


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
