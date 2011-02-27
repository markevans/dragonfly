module Dragonfly
  class Server

    include Loggable
    include Configurable
    
    configurable_attr :protect_from_dos_attacks, false
    configurable_attr :url_format, '/media/:job'
    
    def initialize(app)
      @app = app
      use_same_log_as(app)
      use_as_fallback_config(app)
    end
    
    def call(env)
      request = Rack::Request.new(env)
      params = url_mapper.params_for(request.path_info)
      if params
        job = Job.deserialize(params['job'], app)
        job.validate_sha!(params['sha']) if protect_from_dos_attacks
        Response.new(job, env).to_response
      else
        [404, {'Content-Type' => 'text/plain', 'X-Cascade' => 'pass'}, ['Not found']]
      end
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    rescue Job::NoSHAGiven => e
      [400, {"Content-Type" => 'text/plain'}, ["You need to give a SHA parameter"]]
    rescue Job::IncorrectSHA => e
      [400, {"Content-Type" => 'text/plain'}, ["The SHA parameter you gave (#{e}) is incorrect"]]
    end

    def url_for(job, opts={})
      # TODO TODO TODO TODO TODO TODO TODO TODO TODO 
      # opts = opts.dup
      # host = opts.delete(:host) || url_host
      # suffix = opts.delete(:suffix) || url_suffix
      # suffix = suffix.call(job) if suffix.respond_to?(:call)
      # path = "#{host}#{}#{suffix}"
      # query = opts
      # query.merge!(server.required_params_for(job)) if protect_from_dos_attacks
      # path << "?#{Rack::Utils.build_query(query)}" if query.any?
      # path
    end

    private
    
    attr_reader :app

    def url_mapper
      @url_mapper ||= UrlMapper.new(url_format)
    end

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
