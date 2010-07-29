module Dragonfly
  module Endpoint

    class EmptyJob < StandardError; end

    private

    def response_for_job(job)
      app, temp_object = job.app, job.result
      raise EmptyJob, "Job contains no steps" unless temp_object
      [200, {
        "Content-Type" => app.resolve_mime_type(temp_object),
        "Content-Length" => temp_object.size.to_s,
        "Cache-Control" => "public, max-age=#{app.cache_duration}"
        }, temp_object]
    rescue DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

  end
end
