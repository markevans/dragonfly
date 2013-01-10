module Dragonfly
  class Analyser < Register

    def analyse(name, temp_object, *args)
      if cache_enabled?
        key = [temp_object.unique_id, name, *args]
        cache[key] ||= get(name).call(temp_object, *args)
      else
        get(name).call(temp_object, *args)
      end
    end

    def cache_enabled?
      cache_size > 0
    end

    def cache_size
      @cache_size ||= 100
    end

    attr_writer :cache_size

    def clear_cache!
      @cache = nil
    end

    private

    def cache
      @cache ||= SimpleCache.new(cache_size)
    end

  end
end
