module Dragonfly
  module Config

    module S3

      def self.apply_configuration(app, opts={})
        app.configure do |c|
          c.datastore = DataStorage::S3DataStore.new(opts)
          c.define_remote_url do |uid, *args|
            opts = args.first
            bucket = c.datastore.bucket_name
            if opts && opts[:expires]
              c.datastore.storage.get_object_url(bucket, uid, opts[:expires])
            else
              "http://#{bucket}.s3.amazonaws.com/#{uid}"
            end
          end
        end
      end

    end
  end
end
