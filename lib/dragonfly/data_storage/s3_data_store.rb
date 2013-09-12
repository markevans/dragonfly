require 'fog'
require 'dragonfly/serializer'
require 'dragonfly/utils'

module Dragonfly
  module DataStorage

    class S3DataStore

      # Exceptions
      class NotConfigured < RuntimeError; end

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
        @bucket_name       = opts[:bucket_name]
        @access_key_id     = opts[:access_key_id]
        @secret_access_key = opts[:secret_access_key]
        @region            = opts[:region]
        @use_filesystem    = opts[:use_filesystem]
        @storage_headers   = opts[:storage_headers] || {'x-amz-acl' => 'public-read'}
        @url_scheme        = opts[:url_scheme] || 'http'
        @url_host          = opts[:url_host]
        @use_iam_profile   = opts[:use_iam_profile]
      end

      attr_accessor :bucket_name, :access_key_id, :secret_access_key, :region, :storage_headers, :url_scheme, :url_host, :use_iam_profile
      attr_writer :use_filesystem

      def use_filesystem?
        @use_filesystem != false
      end

      def store(content, opts={})
        ensure_configured
        ensure_bucket_initialized

        headers = {'Content-Type' => content.mime_type}
        headers.merge!(opts[:headers]) if opts[:headers]
        uid = opts[:path] || generate_uid(content.name || 'file')

        rescuing_socket_errors do
          if use_filesystem?
            content.file do |f|
              storage.put_object(bucket_name, uid, f, full_storage_headers(headers, content.meta))
            end
          else
            storage.put_object(bucket_name, uid, content.data, full_storage_headers(headers, content.meta))
          end
        end

        uid
      end

      def retrieve(content, uid)
        ensure_configured
        response = rescuing_socket_errors{ storage.get_object(bucket_name, uid) }
        content.update(response.body, headers_to_meta(response.headers))
      rescue Excon::Errors::NotFound => e
        throw :not_found, uid
      end

      def destroy(uid)
        rescuing_socket_errors{ storage.delete_object(bucket_name, uid) }
      rescue Excon::Errors::NotFound => e
        throw :not_found, uid
      rescue Excon::Errors::Conflict => e
        Dragonfly.warn("S3DataStore destroy error: #{e}")
      end

      def url_for(uid, opts={})
        if opts && opts[:expires]
          storage.get_object_https_url(bucket_name, uid, opts[:expires])
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
          storage = Fog::Storage.new({
            :provider => 'AWS',
            :aws_access_key_id => access_key_id,
            :aws_secret_access_key => secret_access_key,
            :region => region,
            :use_iam_profile => use_iam_profile
          }.reject {|name, option| option.nil?})
          storage.sync_clock
          storage
        end
      end

      def bucket_exists?
        rescuing_socket_errors{ storage.get_bucket_location(bucket_name) }
        true
      rescue Excon::Errors::NotFound => e
        false
      end

      private

      def ensure_configured
        unless @configured
          if use_iam_profile
            raise NotConfigured, "You need to configure #{self.class.name} with bucket_name" if bucket_name.nil?
          else
            [:bucket_name, :access_key_id, :secret_access_key].each do |attr|
              raise NotConfigured, "You need to configure #{self.class.name} with #{attr}" if send(attr).nil?
            end
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
        storage_headers.merge(meta_to_headers(meta)).merge(headers)
      end

      def headers_to_meta(headers)
        json = headers['x-amz-meta-json']
        if json && !json.empty?
          Serializer.json_decode(json)
        elsif marshal_data = headers['x-amz-meta-extra']
          Utils.stringify_keys(Serializer.marshal_b64_decode(marshal_data))
        end
      end

      def meta_to_headers(meta)
        {'x-amz-meta-json' => Serializer.json_encode(meta)}
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
