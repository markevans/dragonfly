module Dragonfly
  class SimpleEndpoint
    
    include Endpoint
    include Loggable
    
    def initialize(app)
      @app = app
    end

    def call(env)
      job = Job.deserialize(env['PATH_INFO'].sub('/',''), @app)
      response_for_job(job)
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end

  end
end
