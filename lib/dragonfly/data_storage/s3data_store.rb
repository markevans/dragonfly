require 'fog'

module Dragonfly
  module DataStorage

    class S3DataStore

      include Configurable
      include Serializer

      configurable_attr :bucket_name
      configurable_attr :access_key_id
      configurable_attr :secret_access_key
      configurable_attr :region
      configurable_attr :use_filesystem, true
      configurable_attr :storage_headers, {'x-amz-acl' => 'public-read'}
      configurable_attr :url_scheme, 'http'
      configurable_attr :url_host

      REGIONS = {
        'us-east-1' => 's3.amazonaws.com',  #default
        'us-west-1' => 's3-us-west-1.amazonaws.com',
        'us-west-2' => 's3-us-west-2.amazonaws.com',
        'ap-northeast-1' => 's3-ap-northeast-1.amazonaws.com',
        'ap-southeast-1' => 's3-ap-southeast-1.amazonaws.com',
        'eu-west-1' => 's3-eu-west-1.amazonaws.com',
        'sa-east-1' => 's3-sa-east-1.amazonaws.com',
        'sa-east-1' => 's3-sa-east-1.amazonaws.com'
      }

      def initialize(opts={})
        self.bucket_name = opts[:bucket_name]
        self.access_key_id = opts[:access_key_id]
        self.secret_access_key = opts[:secret_access_key]
        self.region = opts[:region]
      end

      def store(temp_object, opts={})
        ensure_configured
        ensure_bucket_initialized
        
        headers = opts[:headers] || {}
        mime_type = opts[:mime_type] || opts[:content_type]
        headers['Content-Type'] = mime_type if mime_type
        uid = opts[:path] || generate_uid(temp_object.name || 'file')
        
        rescuing_socket_errors do
          if use_filesystem
            temp_object.file do |f|
              storage.put_object(bucket_name, uid, f, full_storage_headers(headers, temp_object.meta))
            end
          else
            storage.put_object(bucket_name, uid, temp_object.data, full_storage_headers(headers, temp_object.meta))
          end
        end
        
        uid
      end

      def retrieve(uid)
        ensure_configured
        response = rescuing_socket_errors{ storage.get_object(bucket_name, uid) }
        [
          response.body,
          parse_s3_metadata(response.headers)
        ]
      rescue Excon::Errors::NotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        rescuing_socket_errors{ storage.delete_object(bucket_name, uid) }
      rescue Excon::Errors::NotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      rescue Excon::Errors::Conflict => e
        raise DestroyError, "#{e} - #{uid}"
      end

      def url_for(uid, opts={})
        if opts && opts[:expires]
          if storage.respond_to?(:get_object_https_url) # fog's get_object_url is deprecated (aug 2011)
            storage.get_object_https_url(bucket_name, uid, opts[:expires])
          else
            storage.get_object_url(bucket_name, uid, opts[:expires])
          end
        else
          scheme = opts[:scheme] || url_scheme
          host   = opts[:host]   || url_host || "#{bucket_name}.s3.amazonaws.com"
          "#{scheme}://#{host}/#{uid}"
        end
      end

      def domain
        REGIONS[get_region]
      end

      def storage
        @storage ||= begin
          storage = Fog::Storage.new(
            :provider => 'AWS',
            :aws_access_key_id => access_key_id,
            :aws_secret_access_key => secret_access_key,
            :region => region
          )
          storage.sync_clock
          storage
        end
      end

      def bucket_exists?
        rescuing_socket_errors{ storage.get_bucket(bucket_name) }
        true
      rescue Excon::Errors::NotFound => e
        false
      end

      private

      def ensure_configured
        unless @configured
          [:bucket_name, :access_key_id, :secret_access_key].each do |attr|
            raise NotConfigured, "You need to configure #{self.class.name} with #{attr}" if send(attr).nil?
          end
          @configured = true
        end
      end

      def ensure_bucket_initialized
        unless @bucket_initialized
          rescuing_socket_errors{ storage.put_bucket(bucket_name, 'LocationConstraint' => region) } unless bucket_exists?
          @bucket_initialized = true
        end
      end

      def get_region
        reg = region || 'us-east-1'
        raise "Invalid region #{reg} - should be one of #{valid_regions.join(', ')}" unless valid_regions.include?(reg)
        reg
      end

      def generate_uid(name)
        "#{Time.now.strftime '%Y/%m/%d/%H/%M/%S'}/#{rand(1000)}/#{name.gsub(/[^\w.]+/, '_')}"
      end

      def full_storage_headers(headers, meta)
        {'x-amz-meta-extra' => marshal_encode(meta)}.merge(storage_headers).merge(headers)
      end

      def parse_s3_metadata(headers)
        encoded_meta = headers['x-amz-meta-extra']
        (marshal_decode(encoded_meta) if encoded_meta) || {}
      end

      def valid_regions
        REGIONS.keys
      end

      def rescuing_socket_errors(&block)
        yield
      rescue Excon::Errors::SocketError => e
        storage.reload
        yield
      end

    end

  end
end
