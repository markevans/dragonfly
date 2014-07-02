require 'uri'
require 'net/http'
require 'base64'
require 'dragonfly/job/step'
require 'addressable/uri'

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
        @url ||= uri =~ /^\w+:[^\d]/ ? uri : "http://#{uri}"
      end

      def filename
        return if data_uri?
        @filename ||= parse_url(url).path[/[^\/]+$/]
      end

      def data_uri?
        uri =~ /^data:/
      end

      def apply
        if data_uri?
          update_from_data_uri
        else
          data = get_following_redirects(url)
          job.content.update(data, 'name' => filename)
        end
      end

      private

      def get_following_redirects(url, redirect_limit=10)
        raise TooManyRedirects, "url #{url} redirected too many times" if redirect_limit == 0
        response = get(url)
        case response
        when Net::HTTPSuccess then response.body || ""
        when Net::HTTPRedirection then get_following_redirects(response['location'], redirect_limit-1)
        else
          response.error!
        end
      rescue Net::HTTPExceptions => e
        raise ErrorResponse.new(e.response.code.to_i, e.response.body)
      end

      def get(url)
        url = parse_url(url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if url.scheme == 'https'
        response = http.get(url.request_uri)
      end

      def update_from_data_uri
        mime_type, b64_data = uri.scan(/^data:([^;]+);base64,(.*)$/)[0]
        if mime_type && b64_data
          data = Base64.decode64(b64_data)
          ext = app.ext_for(mime_type)
          job.content.update(data, 'name' => "file.#{ext}")
        else
          raise CannotHandle, "fetch_url can only deal with base64-encoded data uris with specified content type"
        end
      end

      def parse_url(url)
        URI.parse(url)
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

    end
  end
end
