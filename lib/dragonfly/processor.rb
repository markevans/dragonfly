module Dragonfly
  class Processor < Register

    # Exceptions
    class ProcessingError < RuntimeErrorWithOriginal; end

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

  end
end
