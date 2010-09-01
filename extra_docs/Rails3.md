Using With Rails 3
==================

Setting up the quick way
------------------------
config/initializers/dragonfly.rb:

    require 'dragonfly/rails/images'

Setting up the more explicit way
--------------------------------
You can do the above explicitly.

config/initializers/dragonfly.rb:

    require 'dragonfly'

    app = Dragonfly[:images]
    app.configure_with(:rmagick)
    app.configure_with(:rails)

    app.define_macro(ActiveRecord::Base, :image_accessor)

application.rb:

    config.middleware.insert_after 'Rack::Lock', 'Dragonfly::Middleware', :images, '/media'
    config.middleware.insert_before 'Dragonfly::Middleware', 'Rack::Cache', {
      :verbose     => true,
      :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
      :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
    }

Gemfile
-------

    gem 'dragonfly', '~>0.7.5'
    gem 'rmagick', :require => 'RMagick'
    gem 'rack-cache', :require => 'rack/cache'

Capistrano
----------
If using Capistrano with the above, you probably will want to keep the cache between deploys, so in deploy.rb:

    namespace :dragonfly do
      desc "Symlink the Rack::Cache files"
      task :symlink, :roles => [:app] do
        run "mkdir -p #{shared_path}/tmp/dragonfly && ln -nfs #{shared_path}/tmp/dragonfly #{release_path}/tmp/dragonfly"
      end
    end
    after 'deploy:update_code', 'dragonfly:symlink'

Use it!
-------

To see what you can do with the model accessors, see {file:Models}.

Mounting in routes.rb
---------------------
Instead of mounting as a middleware, you could skip that bit and mount directly in the routes.rb file:

    match '/media(/:dragonfly)', :to => Dragonfly[:images]

Make sure the the path prefix matches the Dragonfly app's configured url_path_prefix (which is /media by default for Rails).
