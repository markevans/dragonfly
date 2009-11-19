module Dragonfly
  module DataStorage

    class FileDataStore < Base

      include Configurable
    
      configurable_attr :root_path, '/var/tmp/dragonfly'

      def store(temp_object)

        suffix = if temp_object.name.blank?
          'file'
        else
          temp_object.name.sub(/\.[^.]*?$/, '')
        end
        relative_path = relative_storage_path(suffix)

        begin
          while File.exist?(storage_path = absolute_storage_path(relative_path))
            relative_path = increment_path(relative_path)
          end
          storage_dir = File.dirname(storage_path)
          FileUtils.mkdir_p(storage_dir) unless File.exist?(storage_dir)
          FileUtils.cp temp_object.path, storage_path
        rescue Errno::EACCES => e
          raise UnableToStore, e.message
        end
      
        relative_path
      end

      def retrieve(relative_path)
        File.new(absolute_storage_path(relative_path))
      rescue Errno::ENOENT => e
        raise DataNotFound, e.message
      end

      def destroy(relative_path)
        FileUtils.rm absolute_storage_path(relative_path)
        containing_directory = Pathname.new(relative_path).dirname
        containing_directory.ascend do |relative_dir|
          dir = absolute_storage_path(relative_dir)
          FileUtils.rmdir dir if directory_empty?(dir)
        end
      rescue Errno::ENOENT => e
        raise DataNotFound, e.message
      end

      private
    
      def increment_path(path)
        path.sub(/(_(\d+))?$/){ $1 ? "_#{$2.to_i+1}" : '_2' }
      end

      def relative_storage_path(suffix)
        "#{Time.now.strftime '%Y/%m/%d/%H%M%S'}_#{suffix}"
      end
      
      def absolute_storage_path(relative_path)
        File.join(root_path, relative_path)
      end

      def directory_empty?(path)
        Dir.entries(path) == ['.','..']
      end

    end

  end
end
