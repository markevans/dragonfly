module Dragonfly
  class UrlHandler
    
    # Exceptions
    class IncorrectSHA < RuntimeError; end
    class SHANotGiven < RuntimeError; end
    
    include Configurable

    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16
    configurable_attr :path_prefix, ''
    configurable_attr :default_route, ":uid"

    def route
      Route.new "#{path_prefix}/#{default_route}"
    end

    def parse_env(env)
      params = Parameters.new
      attrs = route.parse_url(env['PATH_INFO'], env['QUERY_STRING'])
      params.uid = attrs[:uid]
      params.job = attrs[:job]
      params.sha = attrs[:sha]
      check_for_sha!(params) if protect_from_dos_attacks
      params
    end
      
    def url_for(uid, job_name, job_opts)
      params = Parameters.new
      params.uid      = uid
      params.job_name = job_name
      params.job_opts = job_opts
      params.generate_sha!(secret, sha_length) if protect_from_dos_attacks
      route.to_url(params)
    end

    private

    def check_for_sha!(params)
      raise SHANotGiven, "You need to give a SHA" unless params.sha
      raise IncorrectSHA, "The SHA parameter you gave is incorrect" if params.generate_sha(secret, sha_length) != params.sha
    end

  end
end
