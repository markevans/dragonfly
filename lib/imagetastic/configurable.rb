module Imagetastic
  module Configurable
    
    # Exceptions
    class NothingToConfigure < StandardError; end
    
    def configure(&blk)
      raise NothingToConfigure, "You called configure but there are no configurable attributes" if configuration_hash.empty?
      struct_class = Struct.new(*configuration_hash.keys)
      struct = struct_class.new(*configuration_hash.values)
      yield(struct)
      struct.each_pair{|k,v| configuration_hash[k] = v }
    end
    
    def configuration
      configuration_hash.dup
    end
    
    private
    
    def configurable_attr attribute, default=nil
      configuration_hash[attribute] = default
      class << self
        self # Get the singleton class of the extended object
      end.class_eval do
        # Define the reader on the extended object
        define_method(attribute) do
          configuration_hash[attribute]
        end
      end
    end
    
    def configuration_hash
      @configuration_hash ||= {}
    end
    
  end
end