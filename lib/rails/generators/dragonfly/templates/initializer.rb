require 'dragonfly'

# Configure
Dragonfly.default_app.configure do
  use :imagemagick
  log Rails.logger
  url_format '/media/:job/:basename.:format'
  datastore :file,
    :root_path => Rails.root.join('public/system/dragonfly', Rails.env),
    :server_root => Rails.root.join('public')
end

# Mount as middleware
Rails.application.middleware.insert 1, Dragonfly::Middleware
