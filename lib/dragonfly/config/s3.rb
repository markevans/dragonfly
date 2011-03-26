module Dragonfly
  module Config

    module S3

      def self.apply_configuration(app, opts={})
        app.configure do |c|
          c.datastore = DataStorage::S3DataStore.new(opts)
          c.define_remote_url do |uid|
            "http://#{c.datastore.bucket_name}.s3.amazonaws.com/#{uid}"
          end
        end
      end

    end
  end
end
