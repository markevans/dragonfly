require 'aws/s3'

module Dragonfly
  module DataStorage

    class S3DataStore < Base
  
      include Configurable
      include AWS::S3
  
      configurable_attr :bucket_name
      configurable_attr :access_key_id
      configurable_attr :secret_access_key
      configurable_attr :use_filesystem, true

      def connect!
        AWS::S3::Base.establish_connection!(
          :access_key_id => access_key_id,
          :secret_access_key => secret_access_key
        )
      end

      def create_bucket!
        Bucket.create(bucket_name) unless bucket_names.include?(bucket_name)
      end

      def store(temp_object)
        uid = generate_uid(temp_object.basename || 'file')
        ensure_initialized
        object = use_filesystem ? temp_object.file : temp_object.data
        S3Object.store(uid, object, bucket_name)
        object.close if use_filesystem
        uid
      end

      def retrieve(uid)
        ensure_initialized
        S3Object.value(uid, bucket_name)
      rescue AWS::S3::NoSuchKey => e
        raise DataNotFound, "#{e} - #{uid}"
      end
  
      def destroy(uid)
        ensure_initialized
        S3Object.delete(uid, bucket_name)
      rescue AWS::S3::NoSuchKey => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      private

      def bucket_names
        Service.buckets.map{|bucket| bucket.name }
      end

      def ensure_initialized
        unless @initialized
          connect!
          create_bucket!
          @initialized = true
        end
      end

      def generate_uid(suffix)
        time = Time.now
        "#{time.strftime '%Y/%m/%d/%H/%M/%S'}/#{rand(1000)}/#{suffix}"
      end

    end
    
  end
end
