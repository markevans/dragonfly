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

    def add(name, processor=nil, &block)
      processors[name] = (processor || block)
    end

    attr_reader :processors

    def update_url(name, url_attributes, *args)
      processor = processor(name)
      processor.update_url(url_attributes, *args) if processor.respond_to?(:update_url)
    end

    def process(name, temp_object, *args)
      processor(name).call(temp_object, *args)
    rescue RuntimeError => e
      raise ProcessingError.new("Couldn't process #{temp_object.inspect} - got: #{e}", e)
    end

    def processor(name)
      processors[name.to_sym] || raise(NotDefined, "processor #{name} not registered with #{self}")
    end

    def inspect
      "<#{self.class.name} with processors: #{processors.keys.map{|k| k.to_s }.sort.join(', ')} >"
    end

  end
end
