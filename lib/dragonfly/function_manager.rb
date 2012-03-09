module Dragonfly
  class FunctionManager

    # Exceptions
    class NotDefined < NoMethodError; end
    class UnableToHandle < NotImplementedError; end

    include Loggable
    include Configurable

    def initialize
      @functions = {}
      @objects = []
    end

    def add(name, callable_obj=nil, &block)
      functions[name] ||= []
      functions[name] << (callable_obj || block)
    end

    attr_reader :functions, :objects

    def register(klass, *args, &block)
      obj = klass.new(*args)
      obj.configure(&block) if block
      obj.use_same_log_as(self) if obj.is_a?(Loggable)
      obj.use_as_fallback_config(self) if obj.is_a?(Configurable)
      methods_to_add(obj).each do |meth|
        add meth, obj.method(meth)
      end
      objects << obj
      obj
    end

    def call_last(meth, *args)
      if functions[meth.to_sym]
        functions[meth.to_sym].reverse.each do |function|
          catch :unable_to_handle do
            return function.call(*args)
          end
        end
        # If the code gets here, then none of the registered functions were able to handle the method call
        raise UnableToHandle, "None of the functions registered with #{self} were able to deal with the method call " +
          "#{meth}(#{args.map{|a| a.inspect[0..100]}.join(',')}). You may need to register one that can."
      else
        raise NotDefined, "function #{meth} not registered with #{self}"
      end
    end

    def get_registered(klass)
      objects.reverse.detect{|o| o.instance_of?(klass) }
    end

    def inspect
      "<#{self.class.name} with functions: #{functions.keys.map{|k| k.to_s }.sort.join(', ')} >"
    end

    private

    def methods_to_add(obj)
      methods = obj.public_methods(false).map{|m| m.to_sym }
      methods -= obj.config_methods if obj.is_a?(Configurable)
      methods
    end

  end
end
