module Dragonfly
  class Generator < Register

    # Exceptions
    class GenerationError < RuntimeErrorWithOriginal; end

    def generate(name, *args)
      generator = get(name)
      begin
        content, meta = generator.call(*args)
      rescue RuntimeError => e
        raise GenerationError.new("Couldn't generate #{name.inspect} with arguments #{args.inspect} - got: #{e}", e)
      end
      TempObject.new(content, meta)
    end

    def update_url(name, url_attrs, *args)
      generator = get(name)
      generator.update_url(url_attrs, *args) if generator.respond_to?(:update_url)
    end

  end
end
