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
          job.content.update(response.body || "", 'name' => filename, 'mime_type' => response.content_type)
        end
      end

      private

      def get_following_redirects(url, redirect_limit=10)
        raise TooManyRedirects, "url #{url} redirected too many times" if redirect_limit == 0
        response = get(url)
        case response
        when Net::HTTPSuccess then response
        when Net::HTTPRedirection then
          get_following_redirects(redirect_url(url, response['location']), redirect_limit-1)
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

        request = Net::HTTP::Get.new(url.request_uri)

        if url.user || url.password
          request.basic_auth(url.user, url.password)
        end

        http.request(request)
      end

      def update_from_data_uri
        mime_type, b64_data = uri.scan(/\Adata:([^;]+);base64,(.*)$/)[0]
        if mime_type && b64_data
          data = Base64.decode64(b64_data)
          ext = app.ext_for(mime_type)
          job.content.update(data, 'name' => "file.#{ext}", 'mime_type' => mime_type)
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
