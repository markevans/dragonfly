module Dragonfly
  module Endpoint

    class EmptyJob < StandardError; end

    private

    def response_for_job(job)
      raise EmptyJob, "Job contains no steps" if job.empty?
      temp_object = job.apply
      [200, {
        "Content-Type" => mime_type(job),
        "Content-Length" => temp_object.size.to_s,
        "Cache-Control" => "public, max-age=#{job.app.cache_duration}"
        }, temp_object]
    rescue DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

    def mime_type(job)
      job.mime_type || job.analyse(:mime_type) || job.app.fallback_mime_type
    end

  end
end
