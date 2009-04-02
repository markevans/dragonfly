module Imagetastic
  module Configurable
    
    private
    
    def configurable_attr attribute, default=nil
      instance_variable_set "@#{attribute}", default
      class << self
        self # Get the singleton class of the extended object
      end.class_eval do
        attr_reader attribute # This defines the reader on the extended object
      end
    end
    
  end
end