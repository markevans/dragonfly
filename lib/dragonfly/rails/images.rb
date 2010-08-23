require 'dragonfly'
require 'rack/cache'

### The dragonfly app ###
app = Dragonfly[:images]
app.configure_with(:rails)
app.configure_with(:rmagick)

### Extend active record ###
app.define_macro(ActiveRecord::Base, :image_accessor)

### Insert the middleware ###
# Where the middleware is depends on the version of Rails
middleware = Rails.respond_to?(:application) ? Rails.application.middleware : ActionController::Dispatcher.middleware

middleware.insert 0, Dragonfly::Middleware, :images, app.path_prefix
middleware.insert 0, Rack::Cache, {
  :verbose     => true,
  :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
  :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
}
