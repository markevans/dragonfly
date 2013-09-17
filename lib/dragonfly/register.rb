module Dragonfly
  class Register

    # Exceptions
    class NotFound < RuntimeError; end

    def initialize
      @items = {}
    end

    attr_reader :items

    def add(name, item=nil, &block)
      items[name.to_sym] = item || block || raise(ArgumentError, "you must give either an argument or a block")
    end

    def get(name)
      items[name.to_sym] || raise(NotFound, "#{name.inspect} not registered")
    end

    def names
      items.keys
    end

  end
end

