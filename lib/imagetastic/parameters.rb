require 'rack'

module Imagetastic
  class Parameters

    class << self
      include Configurable
      
      configurable_attr :default_processing_method
      configurable_attr :default_processing_options, {}
      configurable_attr :default_mime_type
      configurable_attr :default_encoding, {}
    end

    attr_accessor :uid, :processing_method, :processing_options, :mime_type, :encoding

    def initialize(attributes={})
      %w(processing_method processing_options mime_type encoding).each do |attribute|
        instance_variable_set "@#{attribute}", (attributes[attribute.to_sym] || self.class.send("default_#{attribute}"))
      end
      @uid = attributes[:uid]
    end

    def [](attribute)
      send(attribute)
    end
    
    def []=(attribute, value)
      send("#{attribute}=", value)
    end
    
    def ==(other_parameters)
      self.to_hash == other_parameters.to_hash
    end
    
    def generate_sha(salt, sha_length)
      Digest::SHA1.hexdigest("#{to_sorted_array}#{salt}")[0...sha_length]
    end

    def to_hash
      {
        :uid => uid,
        :processing_method => processing_method,
        :processing_options => processing_options,
        :mime_type => mime_type,
        :encoding => encoding
      }
    end

    private
    
    def to_sorted_array
      to_hash.sort{|a,b| a[1].to_s <=> b[1].to_s }
    end

  end
end