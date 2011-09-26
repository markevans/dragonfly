module Dragonfly
  module Configurable

    # Exceptions
    class NotConfigured < RuntimeError; end
    class BadConfigAttribute < RuntimeError; end

    def self.included(klass)
      klass.class_eval do
        include Configurable::InstanceMethods
        extend Configurable::ClassMethods
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
      
      def configuration
        @configuration ||= {}
      end
            
      def config_methods
        @config_methods ||= self.class.config_methods.dup
      end
      
      def default_configuration
        @default_configuration ||= self.class.default_configuration.dup
      end

      def set_config_value(key, value)
        configuration[key] = value
        child_configurables.each{|c| c.set_if_unset(key, value) }
        value
      end
      
      def use_as_fallback_config(other_configurable)
        other_configurable.add_child_configurable(self)
        self.fallback_configurable = other_configurable
      end

      protected

      def add_child_configurable(obj)
        child_configurables << obj
        config_methods.push(*obj.config_methods)
        fallback_configurable.config_methods.push(*obj.config_methods) if fallback_configurable
      end

      def set_if_unset(key, value)
        set_config_value(key, value) unless set_locally?(key)
      end

      private
      
      attr_accessor :fallback_configurable
      
      def child_configurables
        @child_configurables ||= []
      end
      
      def set_locally?(key)
        instance_variable_defined?("@#{key}")
      end
      
      def default_value(key)
        if default_configuration[key].is_a?(DeferredBlock)
          default_configuration[key] = default_configuration[key].call
        end
        default_configuration[key]
      end

      def saved_configs
        self.class.saved_configs
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
        @default_configuration ||= configurable_ancestors.reverse.inject({}) do |default_config, klass|
          default_config.merge!(klass.default_configuration)
          default_config
        end
      end

      def config_methods
        @config_methods ||= configurable_ancestors.inject([]) do |conf_methods, klass|
          conf_methods |= klass.config_methods
          conf_methods
        end
      end

      def nested_configurables
        @nested_configurables ||= []
      end

      def register_configuration(name, config=nil, &config_in_block) 
        saved_configs[name] = config_in_block || config
      end

      def saved_configs
        @saved_configs ||= {}
      end

      def configurable_ancestors
        @configurable_ancestors ||= ancestors.select{|a| a.included_modules.include?(Configurable) } - [self]
      end

      private

      def configurable_attr attribute, default=nil, &blk
        default_configuration[attribute] = blk ? DeferredBlock.new(blk) : default

        # Define the reader
        define_method(attribute) do
          configuration.has_key?(attribute) ? configuration[attribute] : default_value(attribute)
        end

        # Define the writer
        define_method("#{attribute}=") do |value|
          instance_variable_set("@#{attribute}", value)
          set_config_value(attribute, value)
        end

        configuration_method attribute
        configuration_method "#{attribute}="
      end

      def configuration_method(*method_names)
        config_methods.push(*method_names.map{|n| n.to_sym }).uniq!
      end
      
      def nested_configurable(*method_names)
        nested_configurables.push(*method_names)
      end

    end

    class ConfigurationProxy

      def initialize(owner)
        @owner = owner
      end

      def method_missing(method_name, *args, &block)
        if owner.has_config_method?(method_name)
          attribute = method_name.to_s.tr('=','').to_sym
          if method_name.to_s =~ /=$/ && owner.has_config_method?(attribute) # a bit hacky - if it has both getter and setter, assume it's a configurable_attr
            owner.set_config_value(attribute, args.first)
          else
            owner.send(method_name, *args, &block)
          end
        elsif nested_configurable?(method_name)
          owner.send(method_name)
        else
          raise BadConfigAttribute, "You tried to configure using '#{method_name.inspect}',  but the valid config attributes are #{owner.config_methods.map{|a| %('#{a.inspect}') }.sort.join(', ')}"
        end
      end

      private

      attr_reader :owner

      def nested_configurable?(method)
        owner.class.nested_configurables.include?(method.to_sym)
      end

    end

  end
end
