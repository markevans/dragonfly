module Dragonfly
  class Processor

    class NoSuchProcessor < RuntimeError; end
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

    attr_reader :processors

    def add(name, processor=nil, &block)
      processors[name] = processor || block
    end

    def process(name, content, *args)
      temp_object = TempObject.new(content)
      original_meta = temp_object.meta
      processor = get(name)
      begin
        content, meta = processor.call(temp_object, *args)
      rescue RuntimeError => e
        raise ProcessingError.new("Couldn't process #{temp_object.inspect} with arguments #{args.inspect} - got: #{e}", e)
      end
      TempObject.new(content, original_meta.merge(meta || {}))
    end

    def update_url(name, url_attrs, *args)
      processor = get(name)
      processor.update_url(url_attrs, *args) if processor.respond_to?(:update_url)
    end

    def get(name)
      processors[name] || raise(NoSuchProcessor, "processor #{name.inspect} not registered")
    end

  end
end
