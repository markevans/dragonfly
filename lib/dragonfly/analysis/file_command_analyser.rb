module Dragonfly
  module Analysis
    
    class FileCommandAnalyser
      
      include Shell
      include Configurable
      
      configurable_attr :file_command, "file"
      configurable_attr :use_filesystem, true
      configurable_attr :num_bytes_to_check, 255
      
      def mime_type(temp_object)
        content_type = if use_filesystem
          `#{file_command} -b --mime #{quote temp_object.path}`
        else
          IO.popen("#{file_command} -b --mime -", 'r+') do |io|
            if num_bytes_to_check
              io.write temp_object.data[0, num_bytes_to_check]
            else
              io.write temp_object.data 
            end
            io.close_write
            io.read
          end
        end.split(';').first
        content_type.strip if content_type
      end
      
    end
    
  end
end
