require 'dragonfly'
require 'uri'

### The dragonfly app ###
app = Dragonfly[:images]
app.configure_with(:rails)
app.configure_with(:imagemagick)

### Extend active record ###
if defined?(ActiveRecord::Base)
  app.define_macro(ActiveRecord::Base, :image_accessor)
  app.define_macro(ActiveRecord::Base, :file_accessor)
end

### Insert the middleware ###
Rails.application.middleware.insert 0, 'Dragonfly::Middleware', :images

begin
  require 'rack/cache'
  Rails.application.middleware.insert_before 'Dragonfly::Middleware', 'Rack::Cache', {
    :verbose     => true,
    :metastore   => URI.encode("file://#{Rails.root}/tmp/dragonfly/cache/meta"), # URI encoded because Windows
    :entitystore => URI.encode("file://#{Rails.root}/tmp/dragonfly/cache/body")  # has problems with spaces
  }
rescue LoadError => e  
  app.log.warn("Warning: couldn't find rack-cache for caching dragonfly content")
end
