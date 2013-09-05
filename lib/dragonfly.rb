require 'rbconfig'
require 'dragonfly/version'
require 'dragonfly/core_ext/object'
require 'dragonfly/core_ext/array'
require 'dragonfly/core_ext/hash'
require 'dragonfly/app'
require 'dragonfly/image_magick/plugin'
require 'dragonfly/data_storage/file_data_store'
require 'dragonfly/data_storage/memory_data_store'
require 'dragonfly/model'
require 'dragonfly/middleware'

if defined?(::Rails)
  require 'dragonfly/railtie'
  require 'dragonfly/model/validations'
end

module Dragonfly
  class << self

    def app(name=nil)
      App.instance(name)
    end

    def running_on_windows?
      !!(RbConfig::CONFIG['host_os'] =~ %r!(msdos|mswin|djgpp|mingw)!)
    end

    # Register plugins so we can do e.g.
    # Dragonfly.app.configure do
    #   plugin :imagemagick
    # end
    App.configurer.register_plugin(:imagemagick){ ImageMagick::Plugin.new }
    App.configurer.register_plugin(:image_magick){ ImageMagick::Plugin.new }

    # Register saved datastores so we can do e.g.
    # Dragonfly.app.configure do
    #   datastore :file
    # end
    App.register_datastore(:file){ DataStorage::FileDataStore }
    App.register_datastore(:memory){ DataStorage::MemoryDataStore }
    App.register_datastore(:s3){
      require 'dragonfly/data_storage/s3_data_store'
      DataStorage::S3DataStore
    }
    App.register_datastore(:couch){
      require 'dragonfly/data_storage/couch_data_store'
      DataStorage::CouchDataStore
    }
    App.register_datastore(:mongo){
      require 'dragonfly/data_storage/mongo_data_store'
      DataStorage::MongoDataStore
    }

  end
end

