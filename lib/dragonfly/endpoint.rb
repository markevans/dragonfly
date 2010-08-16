module Dragonfly
  module Endpoint

    class EmptyJob < StandardError; end

    private

    def response_for_job(job, env)
      if etag_matches?(job, env)
        [304, cache_headers(job), []]
      else
        [200, success_headers(job), job.result] # Successful response
      end
    rescue DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

    def cache_headers(job)
      {
        "Cache-Control" => "public, max-age=#{job.app.cache_duration}",
        "ETag" => %("#{job.unique_signature}")
      }
    end

    def etag_matches?(job, env)
      if_none_match = env['HTTP_IF_NONE_MATCH']
      if if_none_match
        if_none_match.tr!('"','')
        if_none_match.split(',').include?(job.unique_signature) || if_none_match == '*'
      else
        false
      end
    end

    def success_headers(job)
      {
        "Content-Type" => job.app.resolve_mime_type(job.result),
        "Content-Length" => job.size.to_s,
      }.merge(cache_headers(job))
    end

  end
end
