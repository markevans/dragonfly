require 'dragonfly'
require 'rack/cache'

### The dragonfly app ###

app = Dragonfly::App[:images]
app.configure_with(Dragonfly::RMagickConfiguration)
app.configure do |c|
  c.log = RAILS_DEFAULT_LOGGER
  c.datastore.configure do |d|
    d.root_path = "#{Rails.root}/public/system/dragonfly/#{Rails.env}"
  end
  c.url_handler do |u|
    u.protect_from_dos_attacks = false
    u.path_prefix = '/images'
  end
end


### Put rack-cache in front of it ###

metal = Rack::Builder.new do

  use Rack::Cache,
    :verbose     => true,
    :metastore   => 'file:/var/cache/rack/meta',
    :entitystore => 'file:/var/cache/rack/body'
  
  run app
  
end

### Extend active record ###
ActiveRecord::Base.extend Dragonfly::ActiveRecordExtensions
ActiveRecord::Base.register_dragonfly_app(:image, app)
