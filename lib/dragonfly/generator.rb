module Dragonfly
  class Generator < Register

    # Exceptions
    class GenerationError < RuntimeErrorWithOriginal; end

    def generate(name, content, *args)
      generator = get(name)
      begin
        generator.call(content, *args)
      rescue RuntimeError => e
        raise GenerationError.new("Couldn't generate #{name.inspect} with content #{content.inspect} and arguments #{args.inspect} - got: #{e}", e)
      end
    end

    def update_url(name, url_attrs, *args)
      generator = get(name)
      generator.update_url(url_attrs, *args) if generator.respond_to?(:update_url)
    end

  end
end
