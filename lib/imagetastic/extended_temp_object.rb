module Imagetastic
  class ExtendedTempObject < TempObject
    
    # Exceptions
    class NotConfiguredError < RuntimeError; end
    
    class << self
      attr_accessor :app
    end
    
    def analyse(analysis_method, *args)
      check_configured!
      analyser.send(analysis_method, self, *args)
    end
    
    def process(processing_method, *args)
      check_configured!
      self.class.new(processor.send(processing_method, self, *args))
    end
    
    def process!(processing_method, *args)
      check_configured!
      modify_self!(processor.send(processing_method, self, *args))
    end

    def encode(*args)
      check_configured!
      self.class.new(encoder.encode(self, *args))
    end
    
    def encode!(*args)
      check_configured!
      modify_self!(encoder.encode(self, *args))
    end

    private
    
    def analyser
      self.class.app.analyser
    end
    
    def processor
      self.class.app.processor
    end
    
    def encoder
      self.class.app.encoder
    end

    def check_configured!
      raise NotConfiguredError, "#{self.class} has no app set" if self.class.app.nil?
    end

  end
end