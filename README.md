Dragonfly
===========

Dragonfly is a <a href="http://rack.rubyforge.org">Rack</a> framework for on-the-fly image handling.

Ideal for using with Ruby on Rails (2.3 and 3), Sinatra and all that gubbins.

For the lazy Rails user...
--------------------------
**Gemfile**:

    gem 'rmagick',    :require => 'RMagick'
    gem 'rack-cache', :require => 'rack/cache'
    gem 'dragonfly', '~>0.7.5'

**Initializer** (e.g. config/initializers/dragonfly.rb):

    require 'dragonfly/rails/images'

**Migration**:

    add_column :albums, :cover_image_uid, :string

**Model**:

    class Album < ActiveRecord::Base
      image_accessor :cover_image            # 'image_accessor' is provided by Dragonfly
                                             # this defines a reader/writer for cover_image
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

If using Capistrano with the above, you probably will want to keep the cache between deploys, so in deploy.rb:

    namespace :dragonfly do
      desc "Symlink the Rack::Cache files"
      task :symlink, :roles => [:app] do
        run "mkdir -p #{shared_path}/tmp/dragonfly && ln -nfs #{shared_path}/tmp/dragonfly #{release_path}/tmp/dragonfly"
      end
    end
    after 'deploy:update_code', 'dragonfly:symlink'

Using outside of rails, custom storage/processing/encoding/analysis, and more...
--------------------------------------------------------------------------------
Dragonfly is primarily a Rack app, so you can use it as a standalone app, or with Sinatra, Merb, etc.

It's highly customizable, and works with any data type (not just images).

For more info, consult the <a href="http://markevans.github.com/dragonfly"><big><strong>DOCUMENTATION</strong></big></a>

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
