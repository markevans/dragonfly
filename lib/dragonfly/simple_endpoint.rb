module Dragonfly
  class SimpleEndpoint

    include Endpoint
    include Loggable

    # Instance methods

    def initialize(app)
      @app = app
      use_same_log_as(app)
    end

    def call(env)
      case env['PATH_INFO']
      when '', '/'
        dragonfly_response
      else
        job = Job.from_path(env['PATH_INFO'], @app)
        response_for_job(job, env)
      end
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
