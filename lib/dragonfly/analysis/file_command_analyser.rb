module Dragonfly
  module Analysis
    
    class FileCommandAnalyser < Base
      
      include Configurable
      
      configurable_attr :file_command, "file"
      configurable_attr :use_filesystem, false
      
      def mime_type(temp_object)
        if use_filesystem
          `#{file_command} -b --mime '#{temp_object.path}'`
        else
          IO.popen("#{file_command} -b --mime -", 'r+') do |io|
            io.write temp_object.data
            io.close_write
            io.read
          end
        end.split(';').first
      end
      
    end
    
  end
end
