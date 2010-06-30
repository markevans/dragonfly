module Dragonfly
  class Endpoint

    include BelongsToApp

    def initialize(job)
      @job = job
      @app = job.app
    end

    def call(env=nil)
      temp_object = job.apply
      [200, {
        "Content-Type" => mime_type,
        "Content-Length" => temp_object.size.to_s,
        "Cache-Control" => "public, max-age=100"
        }, temp_object]
    rescue DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end
    
    private
    
    attr_reader :job

    def mime_type
      job.mime_type || job.analyse(:mime_type) || app.fallback_mime_type
    end

  end
end
