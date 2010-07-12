module Dragonfly
  class Analyser < FunctionManager
    
    def initialize
      super
      analyser = self
      @analysis_methods = Module.new do
        define_method :analyser do
          analyser
        end
      end
    end
    
    attr_reader :analysis_methods
    
    def analyse(temp_object, method, *args)
      call_last(method, temp_object, *args)
    rescue NotDefined, UnableToHandle => e
      log.warn(e.message)
      nil
    end
    
    # Each time a function is registered with the analyser,
    # add a method to the analysis_methods module.
    # Expects the object that is extended to define 'to_temp_object'
    def add(name, *args, &block)
      analysis_methods.module_eval %(
        def #{name}(*args)
          analyser.analyse(to_temp_object, :#{name}, *args)
        end
      )
      super
    end
    
  end
end
