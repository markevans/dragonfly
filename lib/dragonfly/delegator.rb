module Dragonfly
  module Delegator
    
    include BelongsToApp
    
    # This gets raised if no delegated objects are able to handle
    # the method call, even though they respond to that method.
    class UnableToHandle < StandardError; end
    
    def register(klass, *args, &block)
      object = klass.new(*args)
      object.configure(&block) if block
      object.app = self.app if app_set? && object.is_a?(BelongsToApp)
      registered_objects << object
      object
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
    
    def delegate(meth, *args)
      registered_objects.reverse.each do |object|
        catch :unable_to_handle do
          return object.send(meth, *args) if object.respond_to?(meth)
        end
      end
      # If the code gets here, then none of the registered objects were able to handle the method call
      raise UnableToHandle, "None of the objects registered with #{self} were able to deal with the method call " +
        "#{meth}(#{args.map{|a| a.inspect[0..100]}.join(',')}). You need to register one that can."
    end
    
    def delegatable_methods
      registered_objects.map{|a| a.delegatable_methods }.flatten.uniq
    end
    
    def has_delegatable_method?(method)
      delegatable_methods.include?(method.to_method_name)
    end
    
    private
    
    attr_writer :registered_objects
    
    def method_missing(meth, *args)
      if has_delegatable_method?(meth)
        delegate(meth, *args)
      else
        super
      end
    end
    
  end
end