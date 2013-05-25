module Dragonfly
  class Analyser < Register

    def analyse(name, content, *args)
      if cache_enabled?
        key = [content.unique_id, name, *args]
        cache[key] ||= get(name).call(content, *args)
      else
        get(name).call(content, *args)
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
