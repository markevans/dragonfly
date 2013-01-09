module Dragonfly
  class Register

    # Exceptions
    class NotFound < RuntimeError; end
    class RuntimeErrorWithOriginal < RuntimeError
      def initialize(message, original_error)
        super(message)
        @original_error = original_error
      end
      attr_reader :original_error
    end

    def initialize
      @items = {}
    end

    attr_reader :items

    def add(name, item=nil, &block)
      items[name] = item || block || raise(ArgumentError, "you must give either an argument or a block")
    end

    def get(name)
      items[name] || raise(NotFound, "#{name.inspect} not registered")
    end

    def names
      items.keys
    end

  end
end
