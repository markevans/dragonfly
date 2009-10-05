module Imagetastic
  module Configurable
    
    # Exceptions
    class BadConfigAttribute < StandardError; end
    
    def self.included(klass)
      klass.class_eval do
        include Configurable::InstanceMethods
        extend Configurable::ClassMethods
        
        # This isn't included in InstanceMethods because we need access to 'klass'
        define_method :configuration_hash do
          @configuration_hash ||= klass.default_configuration.dup
        end
        private :configuration_hash
        
      end
    end
    
    module InstanceMethods
      
      def configure(&blk)
        yield ConfigurationProxy.new(self)
      end
    
      def configuration
        configuration_hash.dup
      end
      
      def configuration_methods
        self.class.configuration_methods
      end

      def has_configuration_method?(method_name)
        configuration_methods.include?(method_name.to_sym)
      end
      
      def has_nested_configurable?(method_name)
        self.class.nested_configurables.include?(method_name.to_sym)
      end

    end
    
    module ClassMethods
      
      def default_configuration
        @default_configuration ||= {}
      end
      
      def configuration_methods
        @configuration_methods ||= []
      end
      
      def nested_configurables
        @nested_configurables ||= []
      end
      
      private
      
      def configurable_attr attribute, default=nil, &blk
        default_configuration[attribute] = blk || default
        
        # Define the reader
        define_method(attribute) do
          if configuration_hash[attribute].respond_to? :call
            configuration_hash[attribute] = configuration_hash[attribute].call
          end
          configuration_hash[attribute]
        end
        
        # Define the writer
        define_method("#{attribute}=") do |value|
          configuration_hash[attribute] = value
        end
        
        configuration_method attribute
        configuration_method "#{attribute}="
      end
      
      def configuration_method(method_name)
        configuration_methods << method_name.to_sym
      end
      
      def nested_configurable(method_name)
        nested_configurables << method_name.to_sym
      end
      
    end
    
    class ConfigurationProxy
      
      def initialize(owner)
        @owner = owner
      end
      
      def method_missing(method_name, *args, &block)
        if owner.has_nested_configurable?(method_name)
          owner.send(method_name).configure(&block)
        elsif owner.has_configuration_method?(method_name)
          owner.send(method_name, *args, &block)
        else
          raise BadConfigAttribute, "You tried to configure using '#{method_name.inspect}',  but the valid config attributes are #{owner.configuration_methods.map{|a| %('#{a.inspect}') }.sort.join(', ')}"
        end
      end
      
      private
      
      attr_reader :owner
      
    end
    
  end
end