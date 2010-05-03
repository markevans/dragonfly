module Dragonfly
  
  # An ExtendedTempObject is just a TempObject that belongs to a Dragonfly App.
  # 
  # Because of this, it can make use of the app's registered processors, encoders and analysers
  #
  # Analysis methods can be accessed on the object itself, e.g. for a registered analysis method 'width', we have
  #   temp_object.width    # ===> 280
  #
  # Processing methods can be accessed using 'process', e.g. for a registered process method 'resize', we have
  #   temp_object.process(:resize, {:some => 'option'})    # ===> processed ExtendedTempObject
  #
  # Similarly, encoding with the method 'encode' delegates to the app's registered encoders
  #   temp_object.encode(:png, {:some => 'option'})    # ===> encoded ExtendedTempObject
  #
  # We can use bang methods to operate on the temp_object itself, rather than return a new one:
  #   temp_object.process!(:resize, {:some => 'option'})
  #   temp_object.encode!(:png, {:some => 'option'})
  #
  # You can make use of the app's registered parameter shortcuts (for processing and encoding in one go) using 'transform', e.g.
  #   temp_object.transform('300x200', :gif)       # ===> return a new processed and encoded ExtendedTempObject
  #   temp_object.transform!('300x200', :gif)      # ===> operate on self
  class ExtendedTempObject < TempObject
    
    include BelongsToApp
    
    def initialize(obj, app)
      super(obj)
      self.app = app
      @cache = {}
    end
    
    def process(processing_method, *args)
      self.class.new(processor.send(processing_method, self, *args), app)
    end
    
    def process!(processing_method, *args)
      modify_self!(processor.send(processing_method, self, *args))
    end

    def encode(*args)
      self.class.new(encoder.encode(self, *args), app)
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
    
    # Modify methods, public_methods and respond_to?, because method_missing
    # allows methods from the analyser
    
    def methods(*args)
      (super + analyser.delegatable_methods).uniq
    end
    
    def public_methods(*args)
      (super + analyser.delegatable_methods).uniq
    end
    
    def respond_to?(method)
      super || analyser.has_delegatable_method?(method)
    end

    private

    attr_reader :cache
    
    def flush_cache!
      @cache = {}
    end

    def reset!
      super
      flush_cache!
    end

    def method_missing(method, *args, &block)
      if analyser.has_delegatable_method?(method)
        # Define the method on the instance so we don't use method_missing next time
        class << self; self; end.class_eval do
          define_method method do
            cache[method] ||= analyser.delegate(method, self)
          end
        end
        # Now that it's defined (for next time)
        send(method)
      else
        super
      end
    end
    
    def analyser
      app.analysers
    end
    
    def processor
      app.processors
    end
    
    def encoder
      app.encoders
    end
    
    def parameters_class
      app.parameters_class
    end
    
  end
end