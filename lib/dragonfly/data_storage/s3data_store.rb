require 'fog'

module Dragonfly
  module DataStorage

    class S3DataStore

      include Configurable
      include Serializer

      configurable_attr :bucket_name
      configurable_attr :access_key_id
      configurable_attr :secret_access_key
      configurable_attr :use_filesystem, true

      def initialize(opts={})
        self.bucket_name = opts[:bucket_name]
        self.access_key_id = opts[:access_key_id]
        self.secret_access_key = opts[:secret_access_key]
      end

      def store(temp_object, opts={})
        ensure_initialized!
        uid = opts[:path] || generate_uid(temp_object.name || 'file')
        extra_data = temp_object.attributes
        if use_filesystem
          temp_object.file do |f|
            storage.put_object(bucket_name, uid, f, s3_metadata_for(extra_data))
          end
        else
          storage.put_object(bucket_name, uid, temp_object.data, s3_metadata_for(extra_data))
        end
        uid
      end

      def retrieve(uid)
        response = storage.get_object(bucket_name, uid)
        [
          response.body,
          parse_s3_metadata(response.headers)
        ]
      rescue Excon::Errors::NotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        storage.delete_object(bucket_name, uid)
      end

      private

      def storage
        @storage ||= Fog::Storage.new(
          :provider => 'AWS',
          :aws_access_key_id => access_key_id,
          :aws_secret_access_key => secret_access_key
        )
      end

      def ensure_initialized!
        unless @initialized
          storage.put_bucket(bucket_name)
          @initialized = true
        end
      end

      def generate_uid(name)
        "#{Time.now.strftime '%Y/%m/%d/%H/%M/%S'}/#{rand(1000)}/#{name.gsub(/[^\w.]+/, '_')}"
      end

      def s3_metadata_for(extra_data)
        {'x-amz-meta-extra' => marshal_encode(extra_data)}
      end

      def parse_s3_metadata(headers)
        extra_data = headers['x-amz-meta-extra']
        marshal_decode(extra_data) if extra_data
      end

    end

  end
end
