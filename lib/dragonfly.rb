require 'dragonfly/version'
require 'dragonfly/core'
require 'dragonfly/core_ext/object'
require 'dragonfly/core_ext/array'
require 'dragonfly/core_ext/hash'
require 'dragonfly/app'
require 'dragonfly/image_magick/plugin'
require 'dragonfly/file_data_store'
require 'dragonfly/memory_data_store'
require 'dragonfly/model'
require 'dragonfly/middleware'

if defined?(::Rails)
  require 'dragonfly/railtie'
  require 'dragonfly/model/validations'
end

module Dragonfly
  class << self

    # Register plugins so we can do e.g.
    # Dragonfly.app.configure do
    #   plugin :imagemagick
    # end
    App.register_plugin(:imagemagick){ ImageMagick::Plugin.new }
    App.register_plugin(:image_magick){ ImageMagick::Plugin.new }

    # Register saved datastores so we can do e.g.
    # Dragonfly.app.configure do
    #   datastore :file
    # end
    App.register_datastore(:file){ FileDataStore }
    App.register_datastore(:memory){ MemoryDataStore }

  end
end
