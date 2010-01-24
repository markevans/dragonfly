module Dragonfly
  class AnalyserList
    include Delegator
    
    def mime_type(temp_object)
      registered_objects.reverse.each do |analyser|
        catch :unable_to_handle do
          return analyser.mime_type(temp_object) if analyser.respond_to?(:mime_type)
        end
      end
      nil
    end
    
  end
end
