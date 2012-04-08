require 'fog'

module Dragonfly
  module DataStorage

    class CloudfilesDataStore

      include Configurable
      include Serializer

      configurable_attr :directory
      configurable_attr :key_id
      configurable_attr :username
      configurable_attr :use_filesystem, true
      configurable_attr :region
      configurable_attr :storage_headers, { "X-CDN-Enabled" => "True" }
      attr_accessor :cdn_host

      REGIONS = {
        'ORD1'      => 's3.amazonaws.com',  #default
        'eu-west-1'      => 's3-eu-west-1.amazonaws.com',
        'ap-southeast-1' => 's3-ap-southeast-1.amazonaws.com',
        'us-west-1'      => 's3-us-west-1.amazonaws.com'
      }

      def initialize(opts={})
        self.directory = opts[:directory]
        self.key_id = opts[:key_id]
        self.username = opts[:username]
        self.region = opts[:region]
      end

      def store(temp_object, opts={})
        ensure_configured
        ensure_directory_initialized
        
        meta = opts[:meta] || {}
        headers = opts[:headers] || {}
        uid = opts[:path] || generate_uid(meta[:name] || temp_object.original_filename || 'file')
        
        rescuing_socket_errors do
          if use_filesystem
            temp_object.file do |f|
              storage.put_object(directory, uid, f, full_storage_headers(headers, meta))
            end
          else
            storage.put_object(directory, uid, temp_object.data, full_storage_headers(headers, meta))
          end
        end
        
        uid
      end

      def retrieve(uid)
        ensure_configured
        response = rescuing_socket_errors{ storage.get_object(directory, uid) }
        [
          response.body,
          parse_metadata(response.headers)
        ]
      rescue Excon::Errors::NotFound, Fog::Storage::Rackspace::NotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        rescuing_socket_errors{ storage.delete_object(directory, uid) }
      rescue Excon::Errors::NotFound, Fog::Storage::Rackspace::NotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def url_for(uid, opts={})
        "#{@cdn_host}/#{uid}"
      end

      def domain
        REGIONS[get_region]
      end

      def storage
        @storage ||= Fog::Storage.new(
          :provider => 'Rackspace',
          :rackspace_api_key => key_id,
          :rackspace_username => username
        )
      end

      def directory_exists?
        rescuing_socket_errors do
          dir = storage.directories.detect{|d| d.key == directory }
          if dir
            @cdn_host ||= dir.public_url # cache the cdn url for generating urls once when checking first time
          end
          !dir.nil?
        end
      rescue Excon::Errors::NotFound, Fog::Storage::Rackspace::NotFound => e
        false
      end

      private

      def ensure_configured
        unless @configured
          [:directory, :key_id, :username].each do |attr|
            raise NotConfigured, "You need to configure #{self.class.name} with #{attr}" if send(attr).nil?
          end
          @configured = true
        end
      end

      def ensure_directory_initialized
        unless @directory_initialized
          unless directory_exists?
            rescuing_socket_errors do
              dir = storage.directories.create(:key => directory, :public => true)
              @cdn_host ||= dir.public_url # cache the cdn url for generating urls once when checking first time
            end
          end
          @directory_initialized = true
        end
      end

      def get_region
        reg = region || 'ORD1'
        raise "Invalid region #{reg} - should be one of #{valid_regions.join(', ')}" unless valid_regions.include?(reg)
        reg
      end

      def generate_uid(name)
        "#{Time.now.strftime '%Y/%m/%d/%H/%M/%S'}/#{rand(1000)}/#{name.gsub(/[^\w.]+/, '_')}"
      end

      # FIXME: the meta needs to be encoded, etc
      def full_storage_headers(headers, meta)
        prefix = 'X-Object-Meta-'
        meta_hash = {}
        meta.each_pair do |key, value|
          meta_hash["#{prefix}#{key}"] = value
        end
        meta_hash.merge(storage_headers).merge(headers)
      end

      # FIXME: the meta needs to be decoded, etc
      def parse_metadata(headers)
        prefix = "X-Object-Meta-"
        meta_headers = headers.select{|k, v| k =~ /^#{prefix}/}
        output_headers = {}
        meta_headers.each_pair do |k, v|
          output_headers[k.gsub(/#{prefix}/, '').downcase.to_sym] = v
        end
        output_headers
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
