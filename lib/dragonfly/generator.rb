module Dragonfly
  class Generator < FunctionManager

    def generate(method, *args)
      call_last(method, *args)
    end

  end
end
