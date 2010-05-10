require 'dragonfly'
require 'rack/cache'

### The dragonfly app ###
app = Dragonfly::App[:images]
app.configure_with(Dragonfly::Config::RailsImages)

### Extend active record ###
Dragonfly.active_record_macro(:image, app)

### Insert the middleware ###
# Where the middleware is depends on the version of Rails
middleware = Rails.respond_to?(:application) ? Rails.application.middleware : ActionController::Dispatcher.middleware
middleware.insert_after Rack::Lock, Dragonfly::Middleware, :images
middleware.insert_before Dragonfly::Middleware, Rack::Cache, {
  :verbose     => true,
  :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
  :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
}
