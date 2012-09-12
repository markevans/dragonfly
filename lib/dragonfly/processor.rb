module Dragonfly
  class Processor

    # Exceptions
    class NotDefined < NoMethodError; end
    class ProcessingError < RuntimeError
      def initialize(message, original_error)
        super(message)
        @original_error = original_error
      end
      attr_reader :original_error
    end

    def initialize
      @processors = {}
    end

    def add(name, callable_obj=nil, &block)
      processors[name] = (callable_obj || block)
    end

    attr_reader :processors

    def process(method, temp_object, *args)
      processor = processors[method.to_sym]
      if processor
        begin
          processor.call(temp_object, *args)
        rescue RuntimeError => e
          raise ProcessingError.new("Couldn't process #{temp_object.inspect} - got: #{e}", e)
        end
      else
        raise NotDefined, "processor #{method} not registered with #{self}"
      end
    end

    def inspect
      "<#{self.class.name} with processors: #{processors.keys.map{|k| k.to_s }.sort.join(', ')} >"
    end

  end
end
