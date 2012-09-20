module Dragonfly
  class Register

    def initialize
      @items = {}
    end

    attr_reader :items

    def add(name, item=nil, &block)
      items[name] = item || block
    end

    def delegate_to(object, method_names)
      method_names.each do |method_name|
        add(method_name, object.method(method_name))
      end
    end

    def [](name)
      items[name]
    end

    def item_names
      items.keys
    end

    def inspect
      "<#{self.class.name} with items: #{item_names.map{|k| k.to_s }.sort.join(', ')} >"
    end

  end
end
