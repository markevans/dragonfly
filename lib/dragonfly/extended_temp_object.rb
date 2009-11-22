module Dragonfly
  class ExtendedTempObject < TempObject
    
    # Exceptions
    class NotConfiguredError < RuntimeError; end
    
    class << self
      attr_accessor :app
    end
    
    def process(processing_method, *args)
      self.class.new(processor.send(processing_method, self, *args))
    end
    
    def process!(processing_method, *args)
      modify_self!(processor.send(processing_method, self, *args))
    end

    def encode(*args)
      self.class.new(encoder.encode(self, *args))
    end
    
    def encode!(*args)
      modify_self!(encoder.encode(self, *args))
    end
    
    def transform(*args)
      args.any? ? dup.transform!(*args) : self
    end
    
    def transform!(*args)
      parameters = parameters_class.from_args(*args)
      process!(parameters.processing_method, parameters.processing_options) unless parameters.processing_method.nil?
      encode!(parameters.format, parameters.encoding) unless parameters.format.nil?
      self
    end
    
    # As we create customly configured subclasses of this class, the console
    # gives a confusing output when inspecting, so modify here
    def inspect
      super.sub('Class:','Custom Dragonfly::ExtendedTempObject:')
    end
    
    # Modify methods, public_methods and respond_to?, because method_missing
    # allows methods from the analyser
    
    def methods(*args)
      (super + analyser.callable_methods).uniq
    end
    
    def public_methods(*args)
      (super + analyser.callable_methods).uniq
    end
    
    def respond_to?(method)
      super || analyser.has_callable_method?(method)
    end

    private
    
    def method_missing(method, *args, &block)
      if analyser.has_callable_method?(method)
        # Define the method so we don't use method_missing next time
        instance_var = "@#{method}"
        self.class.class_eval do
          define_method method do
            # Lazy reader, like
            #   @width ||= analyser.width(self)
            instance_variable_set(instance_var, instance_variable_get(instance_var) || analyser.send(method, self))
          end
        end
        # Now that it's defined (for next time)
        send(method)
      else
        super
      end
    end
    
    def app
      self.class.app ? self.class.app : raise(NotConfiguredError, "#{self.class} has no app set")
    end
    
    def analyser
      app.analysers
    end
    
    def processor
      app.processor
    end
    
    def encoder
      app.encoder
    end
    
    def parameters_class
      app.parameters_class
    end

  end
end