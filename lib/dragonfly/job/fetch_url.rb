require 'uri'
require 'net/http'
require 'base64'
require 'dragonfly/job/step'
require 'addressable/uri'
require 'dragonfly/fetch_url_configure'

module Dragonfly
  class Job
    class FetchUrl < Step

      class ErrorResponse < RuntimeError
        def initialize(status, body)
          @status, @body = status, body
        end
        attr_reader :status, :body
      end
      class CannotHandle < RuntimeError; end
      class TooManyRedirects < RuntimeError; end
      class BadURI < RuntimeError; end

      def init
        job.url_attributes.name = filename
      end

      def uri
        args.first
      end

      def url
        @url ||= uri =~ /\A\w+:[^\d]/ ? uri : "http://#{uri}"
      end

      def filename
        return if data_uri?
        @filename ||= parse_url(url).path[/[^\/]+\z/]
      end

      def data_uri?
        uri =~ /\Adata:/
      end

      def apply
        if data_uri?
          update_from_data_uri
        else
          response = get_following_redirects(url)
          Rails.logger.info("Content update before")
          job.content.update(response.body || "", 'name' => filename, 'mime_type' => response.content_type)
          Rails.logger.info("Content update before")
        end
      end

      private

      def url_fetch
        @url_fetch ||= begin
          url_fetch_factory = Dragonfly::FetchUrlConfigure.configuration.url_fetch_factory
          url_fetch_factory.create
        end
      end

      def parse_url(url)
        URI.parse(url.to_s)
      rescue URI::InvalidURIError
        begin
          encoded_uri = Addressable::URI.parse(url).normalize.to_s
          URI.parse(encoded_uri)
        rescue Addressable::URI::InvalidURIError => e
          raise BadURI, e.message
        rescue URI::InvalidURIError => e
          raise BadURI, e.message
        end
      end

      def get_following_redirects(url, redirect_limit=10)
        url_fetch.get_following_redirects(url, redirect_limit)
      end

      def get(url)
        url_fetch.get(url)
      end

      def update_from_data_uri
        mime_type, b64_data = uri.scan(/\Adata:([^;]+);base64,(.*)\Z/m)[0]
        if mime_type && b64_data
          data = Base64.decode64(b64_data)
          ext = app.ext_for(mime_type)
          job.content.update(data, 'name' => "file.#{ext}", 'mime_type' => mime_type)
        else
          raise CannotHandle, "fetch_url can only deal with base64-encoded data uris with specified content type"
        end
      end


      def redirect_url(current_url, following_url)
        redirect_url = URI.parse(following_url)
        if redirect_url.relative?
          redirect_url = URI::join(current_url, following_url)
        end
        redirect_url
      end
    end
  end
end
