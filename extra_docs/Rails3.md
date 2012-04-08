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
    app.configure_with(:imagemagick)
    app.configure_with(:rails)

    app.define_macro(ActiveRecord::Base, :image_accessor)

application.rb:

    config.middleware.insert 0, 'Rack::Cache', {
      :verbose     => true,
      :metastore   => URI.encode("file:#{Rails.root}/tmp/dragonfly/cache/meta"),
      :entitystore => URI.encode("file:#{Rails.root}/tmp/dragonfly/cache/body")
    } # unless Rails.env.production?  ## uncomment this 'unless' in Rails 3.1,
                                      ## because it already inserts Rack::Cache in production
    
    config.middleware.insert_after 'Rack::Cache', 'Dragonfly::Middleware', :images

Gemfile
-------

    gem 'dragonfly', '~>0.9.12'
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
