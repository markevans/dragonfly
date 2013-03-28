module Dragonfly
  class Processor < Register

    # Exceptions
    class ProcessingError < RuntimeErrorWithOriginal; end

    def process(name, job, *args)
      processor = get(name)
      begin
        processor.call(job, *args)
      rescue RuntimeError => e
        raise ProcessingError.new("Couldn't process #{name.inspect} with #{job.inspect} and arguments #{args.inspect} - got: #{e}", e)
      end
    end

    def update_url(name, url_attrs, *args)
      processor = get(name)
      processor.update_url(url_attrs, *args) if processor.respond_to?(:update_url)
    end

  end
end
