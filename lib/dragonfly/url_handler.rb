# encoding: utf-8
require 'digest/sha1'
require 'rack'

module Dragonfly
  class UrlHandler
    
    # Exceptions
    class IncorrectSHA < RuntimeError; end
    class SHANotGiven < RuntimeError; end
    class UnknownUrl < RuntimeError; end
    
    include Rack::Utils
    include Configurable

    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16
    configurable_attr :path_prefix, ''
    configurable_attr :default_route, ['(?<uid>\w+)', {:j => :job, :s => :sha}]

    class Route
      include Rack::Utils
      
      def initialize(path_spec, query_spec)
        @path_spec, @query_spec = path_spec, query_spec
      end

      def parse_url(path, query_string)
        attrs_from_path  = parse_path(path)
        attrs_from_query = parse_query_string(query_string)
        attrs_from_path.merge(attrs_from_query)
      end
      
      def to_url(params)
        # substitute named portions of the path spec with the value from params
        path = %w(uid job).inject(@path_spec) do |path, meth|
          path.sub( /\(\?<#{meth}>[^\(\)]+\)/, escape(params.send(meth) || '') )
        end
        query = @query_spec.inject({}) do |query, (k, meth)|
          value = params.send(meth)
          query[k] = value if value
          query
        end
        query_string = build_query(query)
        [path, query_string].reject{|i| i.blank? }.join('?')
      end
      
      private
      def regexp
        @regexp ||= Regexp.new(@path_spec)
      end
      
      def parse_path(path)
        match_data = regexp.match(path)
        raise UnknownUrl, "path '#{path}' not found" unless match_data
        Hash[[match_data.names, match_data.captures].transpose]
      end
      
      def parse_query_string(query_string)
        query = parse_query(query_string)
        attrs_from_query = @query_spec.inject({}) do |attrs, (k, v)|
          attrs[v.to_s] = query[k.to_s]
          attrs
        end
      end
    end

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
