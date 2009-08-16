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
        params = query_string_to_hash(query_string)
        validate_params(params)
        params
      end
    end
    
    private
    
    def query_string_to_hash(string)
      parse_query(string).inject({}) do |memo, k_and_v|
        k,v = k_and_v
        if k =~ /^(.+)\[(.+)\]$/
          k, k_2 = $1, $2
          memo[k] ||= {}
          memo[k][k_2] = v
        else
          memo[k] = v
        end
        memo
      end
    end
    
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
    
    def sha_for_params(params)
      params_without_sha = params.reject{|k,v| k == 'sha' }
      Digest::SHA1.hexdigest("#{params_without_sha}#{secret}")[0...sha_length]
    end
    
    def blank?(obj)
      obj.nil? || obj.empty?
    end
    
  end
end