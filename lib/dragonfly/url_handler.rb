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
    configurable_attr :default_route do Route.new("(?<uid>\w+)", :j => :job, :s => :sha) end

    class Parameters
      
      include Rack::Utils
      
      def self.from_url(path, query_string, route)
        params = new
        attrs = route.parse_url(path, query_string)
        %w(uid job sha).each do |meth|
          params.send("#{meth}=", attrs[meth])
        end
        params
      end
      
      def initialize(uid=nil, job=nil)
        @uid = uid
        @job_name, *@job_args = job unless job.blank?
      end
      
      attr_accessor :uid, :sha
      attr_reader :job_name, :job_args
      
      def job
        Serializer.marshal_encode([@job_name, *@job_args]) if @job_name
      end
      
      def job=(encoded_job)
        @job_name, *@job_args = Serializer.marshal_decode(encoded_job) if encoded_job
      end
      
      def generate_sha!(secret, length)
        self.sha = generate_sha(secret, length)
      end
      
      def generate_sha(secret, length)
        Digest::SHA1.hexdigest("#{uid}#{job}#{secret}")[0...length]
      end
      
      def to_url(route)
        route
      end
    end

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

    def parse_env(env)
      params = Parameters.from_url(env['PATH_INFO'], env['QUERY_STRING'], default_route)
      validate_params!(params)
      params
    end
      
    def url_for(uid, *job)
      params = Parameters.new(uid, job)
      params.generate_sha!(secret, sha_length) if protect_from_dos_attacks
      default_route.to_url(params)
    end

    private

    def validate_params!(params)
      if protect_from_dos_attacks
        raise SHANotGiven, "You need to give a SHA" unless params.sha
        raise IncorrectSHA, "The SHA parameter you gave is incorrect" if params.generate_sha(secret, sha_length) != params.sha
      end
    end

  end
end
