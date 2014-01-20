require 'uri'
require 'rack'

module Dragonfly
  class Response

    def initialize(job, env)
      @job, @env = job, env
      @app = @job.app
    end

    def to_response
      response = begin
        if !(request.head? || request.get?)
          [405, method_not_allowed_headers, ["method not allowed"]]
        elsif etag_matches?
          [304, cache_headers, []]
        elsif partial_content?
          job.apply
          file_size = @job.size
          #TODO: handle multiple ranges, for now (like Rack), we only handle the first
          ranges = Rack::Utils.byte_ranges(env, file_size)
          job.range = ranges.first if ranges
          range_begin = (job.range && job.range.begin) ? job.range.first : 0  
          range_end = (job.range && job.range.end) ? job.range.last : file_size - 1

          env['dragonfly.job'] = job
          [
            206,
            partial_content_headers(range_begin, range_end, file_size),
            (request.head? ? [] : job)
          ]
        else
          job.apply
          env['dragonfly.job'] = job
          [
            200,
            success_headers,
            (request.head? ? [] : job)
          ]
        end
      rescue Job::Fetch::NotFound => e
        Dragonfly.warn(e.message)
        [404, {"Content-Type" => "text/plain"}, ["Not found"]]
      rescue RuntimeError => e
        Dragonfly.warn("caught error - #{e.message}")
        [500, {"Content-Type" => "text/plain"}, ["Internal Server Error"]]
      end
      log_response(response)
      response
    end

    def will_be_served?
      request.get? && !etag_matches?
    end


    private

    attr_reader :job, :env, :app

    def request
      @request ||= Rack::Request.new(env)
    end

    def log_response(response)
      r = request
      Dragonfly.info [r.request_method, r.fullpath, response[0]].join(' ')
    end

    def etag_matches?
      return @etag_matches unless @etag_matches.nil?
      if_none_match = env['HTTP_IF_NONE_MATCH']
      @etag_matches = if if_none_match
        if_none_match.tr!('"','')
        if_none_match.split(',').include?(job.signature) || if_none_match == '*'
      else
        false
      end
    end

    def partial_content? 
      ! env['HTTP_RANGE'].nil?
    end

    def method_not_allowed_headers
      {
        'Content-Type' => 'text/plain',
        'Allow' => 'GET, HEAD'
      }
    end

    def partial_content_headers(range_begin, range_end, file_size)
      {
        "Content-Type" => job.mime_type,
        "Content-Disposition" => filename_string,
        "Content-Length" => (range_end - range_begin + 1).to_s,
        "Content-Range" => "bytes #{range_begin.to_s}-#{range_end.to_s}/#{file_size.to_s}",
        "Cache-Control" => "public, must-revalidate, max-age=0",
        "Pragma" => "no-cache",
        "Accept-Ranges" =>  "bytes"
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
        "Content-Disposition" => filename_string
      }
    end

    def cache_headers
      {
        "Cache-Control" => "public, max-age=31536000", # (1 year)
        "ETag" => %("#{job.signature}")
      }
    end

    def customize_headers(headers)
      app.response_headers.each do |k, v|
        headers[k] = v.respond_to?(:call) ? v.call(job, request, headers) : v
      end
    end

    def filename_string
      return unless job.name
      filename = request_from_msie? ? URI.encode(job.name) : job.name
      %(filename="#{filename}")
    end

    def request_from_msie?
      env["HTTP_USER_AGENT"] =~ /MSIE/
    end

  end
end
