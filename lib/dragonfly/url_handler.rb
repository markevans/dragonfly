require 'digest/sha1'
require 'rack'

module Dragonfly
  class UrlHandler
    
    # Exceptions
    class IncorrectSHA < RuntimeError; end
    class SHANotGiven < RuntimeError; end
    class UnknownUrl < RuntimeError; end
    
    include Configurable

    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16
    configurable_attr :path_prefix, ''


    class Parameters
      
      include Rack::Utils
      
      def initialize(url_details)
        required_keys = [:host, :path, :query, :path_prefix]
        unless required_keys - url_details.keys == []
          raise ArgumentError, "#{self.class.name} must be initialized with a hash with the keys (#{required_keys.join(', ')})"
        end
        @url_details = url_details
      end
      
      def path_prefix
        @path_prefix ||= url_details[:path_prefix] || ''
      end
      
      def path
        @path ||= unescape(url_details[:path])
      end

      def rel_path
        @rel_path ||= path.sub(path_prefix, '')
      end
      
      def uid
        @uid ||= rel_path.sub(/^\//,'').sub(/\.[^.]+$/, '')
      end
      
      def format
        @format ||= begin
          bits = rel_path.sub(/^\//,'').split('.')
          bits.last.to_sym if bits.length > 1
        end
      end
      
      def query
        @query ||= parse_query(url_details[:query])
      end
      
      def job_args
        @job_args ||= Serializer.marshal_decode(query['j']) if query['j']
      end
      
      def valid?
        path =~ %r(^#{path_prefix}/[^.]+)
      end
      
      private
      attr_reader :url_details
    end

    def url_for(uid, *args)
      parameters = parameters_class.from_args(*args)
      parameters.uid = uid
      parameters_to_url(parameters)
    end

    def parse_env(env)
      url = Parameters.new(
        :host => env['HTTP_HOST'],
        :path => env['PATH_INFO'],
        :query => env['QUERY_STRING'],
        :path_prefix => path_prefix
      )
      raise UnknownUrl, "path '#{url.path}' not found" unless url.valid?
      url
    end

    def parameters_to_url(parameters)
      query_string = [:processing_method, :processing_options, :encoding].map do |attribute|
        build_query(MAPPINGS[attribute] => parameters[attribute]) unless parameters[attribute].blank?
      end.compact.join('&')
      sha_string = "&#{MAPPINGS[:sha]}=#{sha_from_parameters(parameters)}" if protect_from_dos_attacks?
      ext = ".#{parameters.format}" if parameters.format
      url = "#{path_prefix}/#{escape_except_for_slashes(parameters.uid)}#{ext}?#{query_string}#{sha_string}"
      url.sub!(/\?$/,'')
      url
    end

    private
  
    def validate_parameters(parameters, query)
      if protect_from_dos_attacks?
        sha = query[MAPPINGS[:sha]]
        raise SHANotGiven, "You need to give a SHA" if sha.nil?
        raise IncorrectSHA, "The SHA parameter you gave is incorrect" if sha_from_parameters(parameters) != sha
      end
    end
    
    def protect_from_dos_attacks?
      protect_from_dos_attacks
    end
    
    def sha_from_parameters(parameters)
      parameters.generate_sha(secret, sha_length)
    end
    
  end
end