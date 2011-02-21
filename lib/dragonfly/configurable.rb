module Dragonfly
  module Configurable

    # Exceptions
    class BadConfigAttribute < StandardError; end

    def self.included(klass)
      klass.class_eval do
        include Configurable::InstanceMethods
        extend Configurable::ClassMethods

        # We should use configured_class rather than self.class
        # because sometimes this will be the eigenclass of an object
        # e.g. if we configure a module, etc.
        define_method :configured_class do
          klass
        end
      end
    end

    class DeferredBlock # Inheriting from Proc causes errors in some versions of Ruby
      def initialize(blk)
        @blk = blk
      end

      def call
        @blk.call
      end
    end

    module InstanceMethods

      def configure(&block)
        yield ConfigurationProxy.new(self)
        self
      end

      def configure_with(config, *args, &block)
        config = saved_config_for(config) if config.is_a?(Symbol)
        config.apply_configuration(self, *args)
        configure(&block) if block
        self
      end

      def has_config_method?(method_name)
        config_methods.include?(method_name.to_sym)
      end
            
      def config_methods
        @config_methods ||= configured_class.config_methods.dup
      end
      
      def configuration
        @configuration ||= {}
      end
      
      def default_configuration
        @default_configuration ||= configured_class.default_configuration.dup
      end

      def use_as_fallback_config(other_configurable)
        self.fallback_configurable = other_configurable
        other_configurable.config_methods.push(*config_methods)
      end

      protected

      def configured_value(key)
        if config_attr_set?(key)
          configuration[key]
        elsif fallback_configurable
          fallback_configurable.configured_value(key)
        end
      end

      def config_attr_set_anywhere?(key)
        config_attr_set?(key) || fallback_configurable && fallback_configurable.config_attr_set_anywhere?(key)
      end

      private
      
      def config_attr_set?(key)
        configuration.has_key?(key)
      end

      attr_accessor :fallback_configurable

      def default_value(key)
        if default_configuration[key].is_a?(DeferredBlock)
          default_configuration[key] = default_configuration[key].call
        end
        default_configuration[key]
      end

      def saved_configs
        configured_class.saved_configs
      end

      def saved_config_for(symbol)
        config = saved_configs[symbol]
        if config.nil?
          raise ArgumentError, "#{symbol.inspect} is not a known configuration - try one of #{saved_configs.keys.join(', ')}"
        end
        config = config.call if config.respond_to?(:call)
        config
      end

    end

    module ClassMethods

      def default_configuration
        @default_configuration ||= {}
      end

      def config_methods
        @config_methods ||= []
      end

      def register_configuration(name, config=nil, &config_in_block) 
        saved_configs[name] = config_in_block || config
      end

      def saved_configs
        @saved_configs ||= {}
      end

      private

      def configurable_attr attribute, default=nil, &blk
        default_configuration[attribute] = blk ? DeferredBlock.new(blk) : default

        # Define the reader
        define_method(attribute) do
          if config_attr_set_anywhere?(attribute)
            configured_value(attribute)
          else
            default_value(attribute)
          end
        end

        # Define the writer
        define_method("#{attribute}=") do |value|
          configuration[attribute] = value
        end

        configuration_method attribute
        configuration_method "#{attribute}="
      end

      def configuration_method(*method_names)
        config_methods.push(*method_names.map{|n| n.to_sym })
      end

    end

    class ConfigurationProxy

      def initialize(owner)
        @owner = owner
      end

      def method_missing(method_name, *args, &block)
        if owner.has_config_method?(method_name)
          if method_name.to_s =~ /=$/
            owner.configuration[method_name.to_s.tr('=','').to_sym] = args.first
          else
            owner.send(method_name, *args, &block)
          end
        elsif nested_configurable?(method_name, *args)
          owner.send(method_name, *args)
        else
          raise BadConfigAttribute, "You tried to configure using '#{method_name.inspect}',  but the valid config attributes are #{owner.config_methods.map{|a| %('#{a.inspect}') }.sort.join(', ')}"
        end
      end

      private

      attr_reader :owner

      def nested_configurable?(method, *args)
        owner.respond_to?(method) && owner.send(method, *args).is_a?(Configurable)
      end

    end

  end
end