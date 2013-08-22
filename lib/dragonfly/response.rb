require 'uri'

module Dragonfly
  class Response

    def initialize(job, env)
      @job, @env = job, env
      @app = @job.app
    end

    def to_response
      if !(request.head? || request.get?)
        [405, method_not_allowed_headers, ["#{request.request_method} method not allowed"]]
      elsif etag_matches?
        [304, cache_headers, []]
      elsif request.head?
        job.apply
        env['dragonfly.job'] = job
        [200, success_headers, []]
      elsif request.get?
        job.apply
        env['dragonfly.job'] = job
        [200, success_headers, job]
      end
    rescue DataStorage::DataNotFound, DataStorage::BadUID => e
      app.log.warn(e.message)
      [404, {"Content-Type" => 'text/plain'}, ['Not found']]
    end

    def will_be_served?
      request.get? && !etag_matches?
    end

    private

    attr_reader :job, :env, :app

    def request
      @request ||= Rack::Request.new(env)
    end

    def etag_matches?
      return @etag_matches unless @etag_matches.nil?
      if_none_match = env['HTTP_IF_NONE_MATCH']
      @etag_matches = if if_none_match
        if_none_match.tr!('"','')
        if_none_match.split(',').include?(job.unique_signature) || if_none_match == '*'
      else
        false
      end
    end

    def method_not_allowed_headers
      {
        'Content-Type' => 'text/plain',
        'Allow' => 'GET, HEAD'
      }
    end

    def success_headers
      headers = standard_headers.merge(cache_headers)
      customize_headers(headers)
      headers.delete_if{|k, v| v.nil? }
    end

    def standard_headers
      {
        "Content-Type" => job.mime_type,
        "Content-Length" => job.size.to_s,
        "Content-Disposition" => (%(filename="#{URI.encode(job.name)}") if job.name)
      }
    end

    def cache_headers
      {
        "Cache-Control" => "public, max-age=#{app.cache_duration}",
        "ETag" => %("#{job.unique_signature}")
      }
    end

    def customize_headers(headers)
      app.response_headers.each do |k, v|
        headers[k] = v.respond_to?(:call) ? v.call(job, request, headers) : v
      end
    end

  end
end

