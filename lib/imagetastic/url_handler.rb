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
      :processing_method => 'm',
      :processing_options => 'o',
      :encoding => 'e',
      :sha => 's'
    }
 
    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16
    configurable_attr :path_prefix, ''

    def url_to_parameters(path, query_string, parameters_class=nil)
      parameters_class ||= Parameters
      query = parse_nested_query(query_string)
      attributes = {
        :uid => extract_uid(path, query),
        :processing_method => extract_processing_method(path, query),
        :processing_options => extract_processing_options(path, query),
        :mime_type => extract_mime_type(path, query),
        :encoding => extract_encoding(path, query)
      }.reject{|k,v| v.nil? }
      parameters = parameters_class.new(attributes)
      validate_parameters(parameters, query)
      parameters
    end

    def parameters_to_url(parameters)
      query_string = [:processing_method, :processing_options, :encoding].map do |attribute|
        build_query(MAPPINGS[attribute] => parameters[attribute]) unless blank?(parameters[attribute])
      end.compact.join('&')
      extension = extension_from_mime_type(parameters.mime_type)
      sha_string = "&#{MAPPINGS[:sha]}=#{sha_from_parameters(parameters)}" if protect_from_dos_attacks?
      "#{path_prefix}/#{parameters.uid}.#{extension}?#{query_string}#{sha_string}"
    end

    private

    def extract_uid(path, query)
      path.sub(path_prefix, '').sub(/^\//,'').split('.').first
    end
  
    def extract_processing_method(path, query)
      query[MAPPINGS[:processing_method]]
    end
  
    def extract_processing_options(path, query)
      processing_options = query[MAPPINGS[:processing_options]]
      symbolize_keys(processing_options) if processing_options
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
    
    def blank?(object)
      object.nil? || (object.respond_to?(:empty?) ? object.empty? : false)
    end
    
  end
end