module Dragonfly
  class Processor

    # Exceptions
    class NoSuchProcessor < RuntimeError; end
    class ProcessingError < RuntimeError
      def initialize(message, original_error)
        super(message)
        @original_error = original_error
      end
      attr_reader :original_error
    end

    class BuiltProcessor
      def initialize(parent, block)
        @parent = parent
        @block = block
        @current_vars = {}
      end

      def call(temp_object, *args)
        setting_current_vars :method => :call, :temp_object => temp_object do
          instance_exec(*args, &block)
          current_vars[:temp_object]
        end
      end

      def update_url(url_attrs, *args)
        setting_current_vars :method => :update_url, :url_attrs => url_attrs do
          instance_exec(*args, &block)
        end
      end

      private

      attr_reader :block, :parent, :current_vars

      def setting_current_vars(vars)
        @current_vars = vars
        result = yield
        @current_vars = nil
        result
      end

      def process(name, *args)
        case current_vars[:method]
        when :call
          current_vars[:temp_object] = parent.process(name, current_vars[:temp_object], *args)
        when :update_url
          parent.update_url(name, current_vars[:url_attrs], *args)
        end
      end
    end

    def initialize
      @processors = {}
    end

    attr_reader :processors

    def add(name, processor=nil, &block)
      processors[name] = processor || block || raise(ArgumentError, "you must give a processor either as an argument or a block")
    end

    def build(name, &block)
      processors[name] = BuiltProcessor.new(self, block)
    end

    def process(name, content, *args)
      temp_object = TempObject.new(content)
      original_meta = temp_object.meta
      processor = get(name)
      begin
        content, meta = processor.call(temp_object, *args)
      rescue RuntimeError => e
        raise ProcessingError.new("Couldn't process #{name.inspect} with #{temp_object.inspect} and arguments #{args.inspect} - got: #{e}", e)
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

    def names
      processors.keys
    end

  end
end
