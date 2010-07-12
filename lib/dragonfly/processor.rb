module Dragonfly
  class Processor < FunctionManager

    def process(temp_object, method, *args)
      call_last(method, temp_object, *args)
    end

  end
end
