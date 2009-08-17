require 'digest/sha1'
require 'rack'

module Imagetastic
  class UrlHandler
    
    # Exceptions
    class BadParams < RuntimeError; end
    class IncorrectSHA < RuntimeError; end
    class SHANotGiven < RuntimeError; end
    
    include Rack::Utils
    include Configurable
    
    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16

    VALID_PARAM_KEYS = %w{m opts sha}

    def query_to_params(query_string)
      unless blank?(query_string)
        params = parse_nested_query(query_string)
        validate_params(params)
        params
      end
    end
    
    def params_to_query_string(params)
      str = build_query(params)
      str += "&sha=#{sha_for_params(params)}" if protect_from_dos_attacks
      str
    end

    private

    def validate_params(params)
      # SHA
      if protect_from_dos_attacks
        raise SHANotGiven, "You need to give a SHA" if blank?(params['sha'])
        raise IncorrectSHA, "The SHA parameter you gave is incorrect" if sha_for_params(params) != params['sha']
      else
        raise BadParams, "you gave a SHA but DOS protection is switched off" if params['sha']
      end
      # Invalid Keys
      invalid_keys = params.keys - VALID_PARAM_KEYS
      raise BadParams, "invalid parameters: #{invalid_keys.join(', ')}" if invalid_keys.any?
    end
    
    # Annoyingly, the 'build_query' in Rack::Utils doesn't seem to work
    # properly for nested parameters/arrays
    # Taken from http://github.com/sinatra/sinatra/commit/52658061d1205753a8afd2801845a910a6c01ffd
    def build_query(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          build_query(v, "#{prefix}[]")
        } * "&"
      when Hash
        value.map { |k, v|
          build_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
        } * "&"
      else
        "#{prefix}=#{escape(value)}"
      end
    end
    
    def sha_for_params(params)
      params_without_sha = params.reject{|k,v| k == 'sha' }
      Digest::SHA1.hexdigest("#{params_without_sha}#{secret}")[0...sha_length]
    end
    
    def blank?(obj)
      obj.nil? || obj.empty?
    end
    
  end
end