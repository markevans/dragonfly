module Imagetastic
  module Configurable
    
    # Exceptions
    class NothingToConfigure < StandardError; end
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

    end
    
    module ClassMethods
      
      def default_configuration
        @default_configuration ||= {}
      end
      
      private
      
      def configurable_attr attribute, default=nil, &blk
        default_configuration[attribute] = blk ? blk : default
        
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
        
      end
      
    end
    
  end
end