module Imagetastic
  module Configurable
    
    # Exceptions
    class NothingToConfigure < StandardError; end
    class BadConfigAttribute < StandardError; end
    
    def self.included(klass)
      klass.class_eval do
        include Configurable::InstanceMethods
        extend Configurable::ClassMethods
      end
    end
    
    module InstanceMethods
      def configure(&blk)
        raise NothingToConfigure, "You called configure but there are no configurable attributes" if configuration_hash.empty?
        config_attributes = configuration_hash.keys
        struct_class = Struct.new(*config_attributes)
        struct = struct_class.new(*configuration_hash.values)
        begin
          yield(struct)
        rescue NoMethodError => e
          raise BadConfigAttribute, "You tried to configure using '#{e.name}',  but the valid config attributes are #{config_attributes.map{|a| %('#{a}') }.sort.join(', ')}"
        end
        struct.each_pair{|k,v| configuration_hash[k] = v }
      end
    
      def configuration
        configuration_hash.dup
      end
    
      private
    
      def configuration_hash
        @configuration_hash ||= self.class.default_configuration.dup
      end

    end
    
    module ClassMethods
      
      def default_configuration
        @default_configuration ||= {}
      end
      
      private
      
      def configurable_attr attribute, default=nil
        default_configuration[attribute] = default
        # Define the reader method on the instance
        define_method(attribute) do
          configuration_hash[attribute]
        end
      end
      
    end
    
  end
end