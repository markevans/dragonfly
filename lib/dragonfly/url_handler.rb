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
    configurable_attr :default_route, ['(?<uid>\w+)', {:j => :job, :s => :sha}]

    def route
      path_spec, query_spec = default_route
      Route.new "#{path_prefix}/#{path_spec}", query_spec
    end

    def parse_env(env)
      params = Parameters.from_url(env['PATH_INFO'], env['QUERY_STRING'], route)
      check_for_sha!(params) if protect_from_dos_attacks
      params
    end
      
    def url_for(uid, *job)
      params = Parameters.new(uid, job)
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
