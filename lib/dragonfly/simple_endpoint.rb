module Dragonfly
  class SimpleEndpoint
    
    include Endpoint
    include Loggable

    # Class methods
    class << self
      def path_to_job(path, app)
        Job.deserialize(path.sub('/',''), app)
      end
      
      def job_to_path(job)
        "/#{job.serialize}"
      end
    end
    
    # Instance methods
    
    def initialize(app)
      @app = app
      use_same_log_as(app)
    end

    def call(env)
      job = self.class.path_to_job(env['PATH_INFO'], @app)
      response_for_job(job, env)
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end

  end
end
