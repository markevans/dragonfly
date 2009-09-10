require 'digest/sha1'
require 'mime/types'
require 'rack'

module Imagetastic
  class UrlHandler
    
    # Exceptions
    class IncorrectSHA < RuntimeError; end
    class SHANotGiven < RuntimeError; end
    
    include Rack::Utils
    include Configurable
    include Imagetastic::Utils

    MAPPINGS = {
      :method => 'm',
      :options => 'o',
      :encoding => 'e',
      :sha => 's'
    }
 
    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16

    def url_to_parameters(path, query_string)
      parameters = Parameters.new
      query = parse_nested_query(query_string)
      %w(uid method options mime_type encoding).each do |attribute|
        parameters.send("#{attribute}=", send("extract_#{attribute}", path, query))
      end
      validate_parameters(parameters, query)
      parameters
    end

    def parameters_to_url(parameters)
      query_string = [:method, :options, :encoding].map do |attribute|
        build_query(MAPPINGS[attribute] => parameters[attribute])
      end.compact.join('&')
      extension = extension_from_mime_type(parameters.mime_type)
      sha_string = "&#{MAPPINGS[:sha]}=#{sha_from_parameters(parameters)}" if protect_from_dos_attacks?
      "/#{parameters.uid}.#{extension}?#{query_string}#{sha_string}"
    end

    private

    def extract_uid(path, query)
      path.sub(/^\//,'').split('.').first
    end
  
    def extract_method(path, query)
      query[MAPPINGS[:method]]
    end
  
    def extract_options(path, query)
      options = query[MAPPINGS[:options]]
      symbolize_keys(options) if options
    end
  
    def extract_mime_type(path, query)
      mime_type_from_extension(file_extension(path))
    end
  
    def extract_encoding(path, query)
      encoding = query[MAPPINGS[:encoding]]
      symbolize_keys(encoding) if encoding
    end

    def symbolize_keys(hash)
      hash = hash.dup
      hash.each do |key, value|
        hash[key.to_sym] = hash.delete(key)
      end
      hash
    end

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