module Dragonfly
  class Analyser < FunctionManager
    
    def analyse(temp_object, method, *args)
      call_last(method, temp_object, *args)
    end
    
  end
end
