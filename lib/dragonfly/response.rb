require 'uri'

module Dragonfly
  class Response

    DEFAULT_FILENAME = proc{|job, request|
      if job.basename
        extname = job.encoded_extname || (".#{job.ext}" if job.ext)
        "#{job.basename}#{extname}"
      end
    }

    def initialize(job, env)
      @job, @env = job, env
      @app = @job.app
    end

    def to_response
      if etag_matches?
        # Not Modified
        [304, cache_headers, []]
      else
        # Success
        [200, success_headers.merge(cache_headers), job.result]
      end
    rescue DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

    private

    attr_reader :job, :env, :app

    def request
      @request ||= Rack::Request.new(env)
    end

    def cache_headers
      {
        "Cache-Control" => "public, max-age=#{app.cache_duration}",
        "ETag" => %("#{job.unique_signature}")
      }
    end

    def etag_matches?
      if_none_match = env['HTTP_IF_NONE_MATCH']
      if if_none_match
        if_none_match.tr!('"','')
        if_none_match.split(',').include?(job.unique_signature) || if_none_match == '*'
      else
        false
      end
    end

    def success_headers
      {
        "Content-Type" => job.resolve_mime_type,
        "Content-Length" => job.size.to_s
      }.merge(content_disposition_header)
    end

    def content_disposition_header
      parts = []
      parts << content_disposition if content_disposition
      parts << %(filename="#{URI.encode(filename)}") if filename
      parts.any? ? {"Content-Disposition" => parts.join('; ')} : {}
    end

    def content_disposition
      @content_disposition ||= evaluate(app.content_disposition)
    end

    def filename
      @filename ||= evaluate(app.content_filename)
    end

    def evaluate(attribute)
      attribute.respond_to?(:call) ? attribute.call(job, request) : attribute
    end

  end
end
