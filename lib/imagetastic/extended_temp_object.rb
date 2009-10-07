module Imagetastic
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
    
    def respond_to?(method)
      super || analyser.respond_to?(method)
    end

    private
    
    def method_missing(method, *args, &block)
      if analyser.respond_to?(method)
        # Cache the result in an attr_reader
        result = instance_variable_set("@#{method}", analyser.send(method))
        self.class.class_eval{ attr_reader method }
        result
      else
        super
      end
    end
    
    def analyser
      self.class.app.analyser
    rescue NoMethodError
      raise_not_configured
    end
    
    def processor
      self.class.app.processor
    rescue NoMethodError
      raise_not_configured
    end
    
    def encoder
      self.class.app.encoder
    rescue NoMethodError
      raise_not_configured
    end

    def raise_not_configured
      raise NotConfiguredError, "#{self.class} has no app set"
    end

  end
end