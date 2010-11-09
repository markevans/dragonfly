module Dragonfly
  class SimpleEndpoint

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
        path, signature = if !app.protect_from_dos_attacks
          [request.path_info, nil]
        elsif request['s']
          [request.path_info, request['s']]
        else
          [request.path_info.gsub(/\/([^\/]*)$/, ''), $1]
        end

        job = Job.from_path(path, app)
        job.validate_sha!(signature) if app.protect_from_dos_attacks
        Response.new(job, env).to_response
      end
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    rescue Job::NoSHAGiven => e
      [400, {"Content-Type" => 'text/plain'}, ["You need to give a SHA parameter"]]
    rescue Job::IncorrectSHA => e
      [400, {"Content-Type" => 'text/plain'}, ["The SHA parameter you gave (#{e}) is incorrect"]]
    end

    def prepare_path_for(path, job)
      path << "/#{job.sha}"
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

  end
end
