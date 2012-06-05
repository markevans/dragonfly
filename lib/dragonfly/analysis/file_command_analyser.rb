module Dragonfly
  module Analysis
    
    class FileCommandAnalyser
      
      def initialize(opts={})
        @shell = Shell.new
        @file_command       = opts[:file_command] || "file"
        @use_filesystem     = opts.has_key?(:use_filesystem) ? opts[:use_filesystem] : true
        @num_bytes_to_check = opts[:num_bytes_to_check] || 255
      end
      
      attr_accessor :file_command, :use_filesystem, :num_bytes_to_check
      
      def mime_type(temp_object)
        content_type = if use_filesystem
          `#{file_command} -b --mime #{shell.quote temp_object.path}`
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
