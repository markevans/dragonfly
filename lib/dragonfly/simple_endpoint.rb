module Dragonfly
  class SimpleEndpoint

    # Exceptions
    class JobNotAllowed < RuntimeError; end

    include Loggable

    # Instance methods

    def initialize(app)
      @app = app
      use_same_log_as(app)
    end

    def call(env)
      request = Rack::Request.new(env)

      case request.path_info
      when '', '/', app.url_path_prefix
        dragonfly_response
      else
        job = Job.from_path(request.path_info, app)
        validate_job!(job)
        job.validate_sha!(request['s']) if app.protect_from_dos_attacks
        Response.new(job, env).to_response
      end
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    rescue Job::NoSHAGiven => e
      [400, {"Content-Type" => 'text/plain'}, ["You need to give a SHA parameter"]]
    rescue Job::IncorrectSHA => e
      [400, {"Content-Type" => 'text/plain'}, ["The SHA parameter you gave (#{e}) is incorrect"]]
    rescue JobNotAllowed => e
      log.warn(e.message)
      [403, {"Content-Type" => 'text/plain'}, ["Forbidden"]]
    end

    def required_params_for(job)
      {'s' => job.sha}
    end

    private

    attr_reader :app

    def dragonfly_response
      body = <<-DRAGONFLY
          _o|o_
  _~~---._(   )_.---~~_
 (       . \\ / .       )
  `-.~--'  |=|  '--~.-'
  _~-.~'" /|=|\\ "'~.-~_
 (      ./ |=| \\.      )
  `~~`"`   |=|   `"'ME"
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
    
    def validate_job!(job)
      if job.fetch_file_step
        raise JobNotAllowed, "Dragonfly Server doesn't allow requesting job with steps #{job.steps.inspect}"
      end
    end

  end
end
