module Dragonfly
  class ProcessorShortcuts < Module

    def initialize
      @processor_shortcuts = {}
    end

    def add(name, &definition_proc)
      processor_shortcuts[name] = ProcessorBuilder.new(&definition_proc)
      ps = processor_shortcuts

      define_method name do |*args|
        ps[name].build(self, *args)
      end

      define_method "#{name}!" do |*args|
        ps[name].build!(self, *args)
      end
    end

    def names
      processor_shortcuts.keys
    end

    private

    attr_reader :processor_shortcuts

  end
end
