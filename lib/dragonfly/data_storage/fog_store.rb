require 'fog'

module Dragonfly
  module DataStorage

    class FogStore

      include Configurable
      include Serializer

      configurable_attr :provider
      configurable_attr :bucket_name
      configurable_attr :google_storage_access_key_id
      configurable_attr :google_storage_secret_access_key
      configurable_attr :aws_access_key_id
      configurable_attr :aws_secret_access_key
      configurable_attr :rackspace_username
      configurable_attr :rackspace_api_key
      configurable_attr :region
      configurable_attr :use_filesystem, true
      # configurable_attr :storage_headers, {'x-amz-acl' => 'public-read'}
      configurable_attr :url_scheme, 'http'
      configurable_attr :url_host


      def initialize(opts={})
        self.provider = opts[:provider]
        self.bucket_name = opts[:bucket_name]
        self.google_storage_access_key_id = opts[:google_storage_access_key_id]
        self.google_storage_secret_access_key = opts[:google_storage_secret_access_key]
        self.rackspace_username = opts[:rackspace_username]
        self.rackspace_api_key = opts[:rackspace_api_key]
        # self.aws_access_key_id = opts[:access_key_id]
        # self.aws_secret_access_key = opts[:secret_access_key]
        # self.region = opts[:region]
      end

      def store(temp_object, opts={})
        ensure_configured
        ensure_bucket_initialized
        
        # headers = opts[:headers] || {}
        # mime_type = opts[:mime_type] || opts[:content_type]
        # headers['Content-Type'] = mime_type if mime_type
        uid = opts[:path] || generate_uid(temp_object.name || 'file')
        
        rescuing_socket_errors do
          if use_filesystem
            temp_object.file do |f|
              storage.put_object(bucket_name, uid, f)
            end
          else
            storage.put_object(bucket_name, uid, temp_object.data)
          end
        end
        
        return uid
      end

      def retrieve(uid)
        ensure_configured
        response = rescuing_socket_errors{ storage.get_object(bucket_name, uid) }
        [
          response.body,
          nil #response.headers 
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
          host   = opts[:host]   || url_host 
          "#{scheme}://#{host}/#{uid}"
        end
      end

      def storage
        @storage ||= begin
          case provider
            # when :aws
            #   storage = Fog::Storage.new(
            #     :provider => 'AWS',
            #     :aws_aws_access_key_id => aws_access_key_id,
            #     :aws_aws_secret_access_key => aws_secret_access_key,
            #     :region => region
            #   )
            raise ArgumentError.new('Please use Dragonfly::DataStorage::S3DataStore for AWS')
          when :google
            storage = Fog::Storage.new(
              :provider                         => 'Google',
              :google_storage_access_key_id     => google_storage_access_key_id,
              :google_storage_secret_access_key => google_storage_secret_access_key
            )
          when :rackspace
            storage = Fog::Storage.new(
              :provider           => 'Rackspace',
              :rackspace_username => rackspace_username,
              :rackspace_api_key  => rackspace_api_key
            )
          else
            raise ArgumentError.new('Please specify PROVIDER to use, choose one of [Google, Rackspace]')
          end
          # storage.sync_clock
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
          raise ArgumentError.new('Please specify PROVIDER to use, choose one of [Google, Rackspace]') unless [:google, :rackspace].include?(provider)
          group = {google: [:google_storage_access_key_id, :google_storage_secret_access_key], rackspace: [:rackspace_username, :rackspace_api_key]}
          group[provider].each do |attr|
            raise NotConfigured, "You need to configure #{self.class.name} with #{attr}" if send(attr).nil?
          end
          @configured = true
        end
      end

      def ensure_bucket_initialized
        unless @bucket_initialized
          rescuing_socket_errors{ storage.put_bucket(bucket_name) } unless bucket_exists?
          @bucket_initialized = true
        end
      end

      def generate_uid(name)
        "#{Time.now.strftime '%Y/%m/%d/%H/%M/%S'}/#{rand(1000)}/#{name.gsub(/[^\w.]+/, '_')}"
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
