module Dragonfly
  class Delegator
    
    # This gets raised if no delegated objects are able to handle
    # the method call, even though they respond to that method.
    class UnableToHandle < StandardError; end
    
    def register(klass, *args, &block)
      object = klass.new(*args)
      object.configure(&block) if block
      registered_objects << object
    end
    
    def unregister(klass)
      registered_objects.delete_if{|obj| obj.is_a?(klass) }
    end
    
    def unregister_all
      self.registered_objects = []
    end
    
    def registered_objects
      @registered_objects ||= []
    end
    
    def callable_methods
      registered_objects.map{|a| a.class.delegatable_methods }.flatten.uniq
    end
    
    def has_callable_method?(method)
      callable_methods.include?(method.to_s)
    end
    
    private
    
    attr_writer :registered_objects
    
    def method_missing(meth, *args)
      registered_objects.reverse.each do |object|
        catch :unable_to_handle do
          return object.send(meth, *args) if object.respond_to?(meth)
        end
      end
      raise UnableToHandle, "None of the registered objects for #{self} were able to deal with the method call " +
        "#{meth}(#{args.map{|a| a.inspect}.join(',')}), even though the method is implemented" if self.has_callable_method?(meth)
      super
    end
    
  end
end