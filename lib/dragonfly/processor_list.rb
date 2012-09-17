module Dragonfly
  class ProcessorList

    def initialize
      @processors = {}
    end

    attr_reader :processors

    def add(name, processor=nil, &block)
      processors[name] = processor || block
    end

    def delegate_to(object, method_names)
      method_names.each do |method_name|
        add(method_name, object.method(method_name))
      end
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
