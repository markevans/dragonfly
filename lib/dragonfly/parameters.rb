require 'rack'

module Dragonfly
  class Parameters
    
    # Exceptions
    class InvalidParameters < RuntimeError; end
    class InvalidShortcut < RuntimeError; end

    # Class methods
    class << self
      
      include Configurable
      
      configurable_attr :default_processing_method
      configurable_attr :default_processing_options, {}
      configurable_attr :default_mime_type
      configurable_attr :default_encoding, {}
      
      def add_shortcut(*args, &block)
        if block
          block_shortcuts_of_length(args.length) << [args, block]
        else
          shortcut_name, attributes = args
          simple_shortcuts[shortcut_name] = attributes
        end
      end
      configuration_method :add_shortcut
      
      def from_shortcut(*args)
        if attributes = matching_simple_shortcut(args)
          new(attributes)
        elsif attributes = matching_block_shortcut(args)
          new(attributes)
        else
          raise InvalidShortcut, "No shortcut was found matching (#{args.map{|a| a.inspect }.join(', ')})"
        end
      end
      
      private
      
      def simple_shortcuts
        @simple_shortcuts ||= {}
      end
      
      # block_shortcuts is actually a hash (keyed on the number of
      # arguments) of arrays (of argument lists)
      def block_shortcuts
        @block_shortcuts ||= {}
      end
      
      def block_shortcuts_of_length(arg_length)
        block_shortcuts[arg_length] ||= []
      end
      
      def matching_simple_shortcut(args)
        if args.length == 1 && args.first.is_a?(Symbol)
          simple_shortcuts[args.first]
        end
      end
      
      def matching_block_shortcut(args)
        block_shortcuts_of_length(args.length).each do |(args_to_match, block)|
          return block.call(*args) if all_args_match?(args, args_to_match)
        end
        nil
      end
      
      def all_args_match?(args, args_to_match)
        (0...args.length).inject(true){|current_result, i| current_result &&= args_to_match[i] === args[i] }
      end

    end

    # Instance methods

    attr_accessor :uid, :processing_method, :processing_options, :mime_type, :encoding

    def initialize(attributes={})
      attributes = attributes.dup
      %w(processing_method processing_options mime_type encoding).each do |attribute|
        instance_variable_set "@#{attribute}", (attributes.delete(attribute.to_sym) || self.class.send("default_#{attribute}"))
      end
      @uid = attributes.delete(:uid)
      raise ArgumentError, "Parameters doesn't recognise the following parameters: #{attributes.keys.join(', ')}" if attributes.any?
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
    
    def unique_signature
      generate_sha('I like cheese', 10)
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

    def validate!
      raise InvalidParameters, "Parameters requires that at least the uid and the mime_type are set" if uid.nil? || mime_type.nil?
    end

    private
    
    def to_sorted_array
      [
        uid,
        mime_type,
        processing_method,
        processing_options.sort{|a,b| a[1].to_s <=> b[1].to_s },
        encoding.sort{|a,b| a[1].to_s <=> b[1].to_s }
      ]
    end

  end
end