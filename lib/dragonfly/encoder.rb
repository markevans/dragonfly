module Dragonfly
  class Encoder < FunctionManager
    
    def add(name=:encode, callable_obj=nil, &block)
      super(name, callable_obj, &block)
    end
    
    def encode(temp_object, *args)
      call_last(:encode, temp_object, *args)
    end

  end
end
