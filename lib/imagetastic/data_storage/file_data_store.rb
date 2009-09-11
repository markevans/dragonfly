module Imagetastic
  module DataStorage

    class FileDataStore < DataStore

      include Configurable
    
      configurable_attr :root_path, '/var/tmp/imagetastic'

      def store(image)

        relative_path = "#{Time.now.strftime '%Y/%m/%d/%H_%M_%S'}_image"

        begin
          while File.exist?(storage_path = absolute_storage_path(relative_path))
            relative_path = increment_path(relative_path)
          end
          FileUtils.mkdir_p File.dirname(storage_path) unless File.exist?(storage_path)
          FileUtils.cp image.path, storage_path
        rescue Errno::EACCES => e
          raise UnableToStore, e.message
        end
      
        relative_path
      end

      def retrieve(relative_path)
        begin
          file = File.new(absolute_storage_path(relative_path), 'r')
          Imagetastic::Image.new(file)
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
