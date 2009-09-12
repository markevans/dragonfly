module Imagetastic
  module DataStorage

    class FileDataStore < Base

      include Configurable
    
      configurable_attr :root_path, '/var/tmp/imagetastic'

      def store(temp_object)

        relative_path = "#{Time.now.strftime '%Y/%m/%d/%H_%M_%S'}_file"

        begin
          while File.exist?(storage_path = absolute_storage_path(relative_path))
            relative_path = increment_path(relative_path)
          end
          FileUtils.mkdir_p File.dirname(storage_path) unless File.exist?(storage_path)
          FileUtils.cp temp_object.path, storage_path
        rescue Errno::EACCES => e
          raise UnableToStore, e.message
        end
      
        relative_path
      end

      def retrieve(relative_path)
        begin
          Imagetastic::TempObject.from_file(absolute_storage_path(relative_path))
        rescue Errno::ENOENT => e
          raise DataNotFound, e.message
        end
      end

      private
    
      def increment_path(path)
        path.sub(/(_(\d+))?$/){ $1 ? "_#{$2.to_i+1}" : '_2' }
      end
      
      def absolute_storage_path(relative_path)
        File.join(root_path, relative_path)
      end

    end

  end
end
