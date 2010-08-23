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
      return dragonfly_response if env['PATH_INFO'] == '/'
      job = self.class.path_to_job(env['PATH_INFO'], @app)
      response_for_job(job, env)
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end

    private

    def dragonfly_response
      body = <<-DRAGONFLY
          _o|o_
  _~~---._(   )_.---~~_
 (       . \\ / .       )
  `-.~--'  |=|  '--~.-'
  _~-.~'" /|=|\\ "'~.-~_
 (      ./ |=| \\.      )
  `~~`"`   |=|   `"'~~"
           |-|
           <->
            V
      DRAGONFLY
      [200, {
        'Content-Type' => 'text/plain',
        'Content-Size' => body.bytesize.to_s
        },
        [body]
      ]
    end

  end
end
