module Dragonfly
  module Config

    module Heroku

      def self.apply_configuration(app, bucket_name)
        app.configure do |c|
          c.datastore = Dragonfly::DataStorage::S3DataStore.new
          c.datastore.configure do |d|
            d.bucket_name = bucket_name
            d.access_key_id = ENV['S3_KEY'] || raise("ENV variable 'S3_KEY' needs to be set - use\n\theroku config:add S3_KEY=XXXXXXXXX")
            d.secret_access_key = ENV['S3_SECRET'] || raise("ENV variable 'S3_SECRET' needs to be set - use\n\theroku config:add S3_SECRET=XXXXXXXXX")
          end
        end
      end

    end
  end
end
