require 'uri'
require 'open-uri'
require 'base64'
require 'dragonfly/job/step'

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

      def init
        job.url_attributes.name = filename
      end

      def uri
        args.first
      end

      def url
        @url ||= uri =~ /^\w+:/ ? uri : "http://#{uri}"
      end

      def filename
        return if data_uri?
        @filename ||= URI.parse(url).path[/[^\/]+$/]
      end

      def data_uri?
        uri =~ /^data:/
      end

      def apply
        if data_uri?
          update_from_data_uri
        else
          open(URI.escape(url)) do |f|
            job.content.update(f.read, 'name' => filename)
          end
        end
      rescue OpenURI::HTTPError => e
        status, message = e.io.status
        raise ErrorResponse.new(status.to_i, e.io.read)
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

    end
  end
end
