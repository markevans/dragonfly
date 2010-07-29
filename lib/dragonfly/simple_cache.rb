module Dragonfly
  class SimpleCache < Hash
    
    def initialize(max_size)
      @max_size = max_size
      @keys = []
    end
    
    attr_reader :max_size
    
    def []=(key, value)
      if !has_key?(key)
        @keys << key
        if size == max_size
          key_to_purge = @keys.shift
          delete(key_to_purge)
        end
      end
      super
    end
    
  end
end
