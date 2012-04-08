module Dragonfly
  module Config

    module Rackspace

      def self.apply_configuration(app, directory)
        app.configure do |c|
          c.datastore = DataStorage::CloudfilesDataStore.new
          c.datastore.configure do |d|
            d.directory = directory
            d.key_id = ENV['RACKSPACE_KEY'] || raise("ENV variable 'RACKSPACE_KEY' needs to be set")
            d.username = ENV['RACKSPACE_USERNAME'] || raise("ENV variable 'RACKSPACE_USERNAME' needs to be set")
          end
        end
      end

    end
  end
end
