require 'digest/sha1'
require 'mime/types'
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

    MAPPINGS = {
      'm' => :method,
      'o' => :options,
      'e' => :encoding,
      's' => :sha
    }
    REVERSE_MAPPINGS = MAPPINGS.invert
    
    def url_to_parameters(path, query_string)
      params = parse_nested_query(query_string)
      map_query_keys(params, MAPPINGS)
      uid, ext = parse_path(path)
      params[:encoding] ||= {}
      params[:encoding][:mime_type] = mime_type_from_extension(ext)
      params[:uid] = uid
      validate_params(params, params.delete(:sha))
      params
    end
    
    def parameters_to_url(params)
      sha_string = "&#{REVERSE_MAPPINGS[:sha]}=#{sha_for_params(params)}" if protect_from_dos_attacks?
      hash_for_url = params.dup
      hash_for_url[:encoding] = params[:encoding].dup
      uid = hash_for_url.delete(:uid)
      ext = extension_from_mime_type(hash_for_url[:encoding].delete(:mime_type))
      map_query_keys(hash_for_url, REVERSE_MAPPINGS)
      query_string = build_query(hash_for_url)
      query_string += sha_string if sha_string
      "/#{uid}.#{ext}?#{query_string}"
    end

    private

    def validate_params(params, sha=nil)
      # SHA
      if protect_from_dos_attacks?
        raise SHANotGiven, "You need to give a SHA" if blank?(sha)
        raise IncorrectSHA, "The SHA parameter you gave is incorrect" if sha_for_params(params) != sha
      else
        raise BadParams, "you gave a SHA but DOS protection is switched off" if sha
      end
      # Invalid Keys
      invalid_keys = params.keys - (MAPPINGS.values + [:uid])
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
    
    def map_query_keys(params, mappings)
      mappings.each do |url_key, params_key|
        if params[url_key]
          value = params.delete(url_key)
          params[params_key] = value
          # Symbolize the keys of this nested hash if a hash
          if value.is_a?(Hash)
            value.each do |k,v|
              value[k.to_sym] = value.delete(k)
            end
          end
        end
      end
    end
    
    def parse_path(path)
      path.sub(/^\//,'').split('.')
    end
    
    def mime_type_from_extension(ext)
      MIME::Types.type_for(ext).to_s
    end
    
    def extension_from_mime_type(mime_type)
      MIME::Types[mime_type].first.extensions.first
    end
    
    def sha_for_params(params)
      Digest::SHA1.hexdigest("#{params}#{secret}")[0...sha_length]
    end
    
    def blank?(obj)
      obj.nil? || obj.empty?
    end
    
    def protect_from_dos_attacks?
      protect_from_dos_attacks
    end
    
  end
end