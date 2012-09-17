module Dragonfly
  class ProcessorList

    def initialize
      @processors = {}
    end

    attr_reader :processors

    def add(name, processor=nil, &block)
      processors[name] = processor || block
    end

    def [](name)
      processors[name]
    end

    def processor_names
      processors.keys
    end

    def inspect
      "<#{self.class.name} with processors: #{processors.keys.map{|k| k.to_s }.sort.join(', ')} >"
    end

  end
end
