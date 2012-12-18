module Dragonfly
  class Generator

    # Exceptions
    class NoSuchGenerator < RuntimeError; end
    class GenerationError < RuntimeError
      def initialize(message, original_error)
        super(message)
        @original_error = original_error
      end
      attr_reader :original_error
    end

    def initialize
      @generators = {}
    end

    attr_reader :generators

    def add(name, generator=nil, &block)
      generators[name] = generator || block
    end

    def generate(name, *args)
      generator = get(name)
      begin
        content, meta = generator.call(*args)
      rescue RuntimeError => e
        raise GenerationError.new("Couldn't generate #{name.inspect} with arguments #{args.inspect} - got: #{e}", e)
      end
      TempObject.new(content, meta)
    end

    def get(name)
      generators[name] || raise(NoSuchGenerator, "generator #{name.inspect} not registered")
    end
    
  end
end
