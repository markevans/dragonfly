module Dragonfly
  class Encoder < FunctionManager
    
    def encode(temp_object, *args)
      call_last(:encode, temp_object, *args)
    end

  end
end
