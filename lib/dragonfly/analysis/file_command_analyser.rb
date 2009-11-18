module Dragonfly
  module Analysis
    
    class FileCommandAnalyser < Base
      
      include Configurable
      
      configurable_attr :file_command do `which file`.chomp end
      
      def mime_type(temp_object)
        output = `#{file_command} -b --mime #{temp_object.path}`
        output.split(';').first
      end
      
    end
    
  end
end
