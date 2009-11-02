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
      dup.transform!(*args)
    end
    
    def transform!(*args)
      parameters = parameters_class.from_args(*args)
      process!(parameters.processing_method, parameters.processing_options) unless parameters.processing_method.nil?
      encode!(parameters.mime_type, parameters.encoding) unless parameters.mime_type.nil?
      self
    end
    
    def respond_to?(method)
      super || analyser.respond_to?(method)
    end

    private
    
    def method_missing(method, *args, &block)
      if analyser.respond_to?(method)
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
      app.analyser
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