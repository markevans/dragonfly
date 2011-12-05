module Dragonfly
  class Analyser < FunctionManager
    
    configurable_attr :enable_cache, true
    configurable_attr :cache_size, 100
    
    def initialize
      super
      analyser = self
      @analysis_methods = Module.new do

        define_method :analyser do
          analyser
        end
        
      end
      @analysis_method_names = []
    end
    
    attr_reader :analysis_methods, :analysis_method_names
    
    def analyse(temp_object, method, *args)
      if enable_cache
        key = [temp_object.unique_id, method, *args]
        cache[key] ||= call_last(method, temp_object, *args)
      else
        call_last(method, temp_object, *args)
      end
    rescue NotDefined, UnableToHandle => e
      log.warn(e.message)
      nil
    end
    
    # Each time a function is registered with the analyser,
    # add a method to the analysis_methods module.
    # Expects the object that is extended to define 'analyse(method, *args)'
    def add(name, *args, &block)
      analysis_methods.module_eval %(
        def #{name}(*args)
          analyse(:#{name}, *args)
        end
      )
      analysis_method_names << name.to_sym
      super
    end
    
    def clear_cache!
      @cache = nil
    end
    
    private
    
    def cache
      @cache ||= SimpleCache.new(cache_size)
    end
    
  end
end
